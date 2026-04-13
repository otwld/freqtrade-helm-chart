#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
NAMESPACE="${NAMESPACE:-freqtrade-v2}"
RELEASE="${RELEASE:-}"
BASE_PORT="${BASE_PORT:-18080}"
ADDRESS="${ADDRESS:-127.0.0.1}"
STATE_DIR="${STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/freqtrade-bot-access}"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  list     Print discovered bots and login details
  start    Start port-forwards for all discovered bots
  stop     Stop all managed port-forwards for the namespace/release
  status   Show discovered bots and current port-forward status

Environment overrides:
  NAMESPACE   Kubernetes namespace to inspect (default: freqtrade-v2)
  RELEASE     Optional Helm release filter via app.kubernetes.io/instance
  BASE_PORT   First local port for port-forwards (default: 18080)
  ADDRESS     Bind address for kubectl port-forward (default: 127.0.0.1)
  STATE_DIR   Where PID/log/state files are stored
EOF
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

state_key() {
  local release_key
  release_key="${RELEASE:-all}"
  printf "%s__%s" "$NAMESPACE" "$release_key"
}

state_file() {
  mkdir -p "$STATE_DIR"
  printf "%s/%s.json" "$STATE_DIR" "$(state_key)"
}

release_selector() {
  if [[ -n "$RELEASE" ]]; then
    printf 'app.kubernetes.io/instance=%s,' "$RELEASE"
  fi
}

discover_bots_json() {
  local selector
  selector="$(release_selector)freqtrade.io/component=bot"

  kubectl get svc,secret,ingress -n "$NAMESPACE" -l "$selector" -o json | jq -c '
    def secret_json:
      (.data["config-private.json"] // "" | @base64d | fromjson? // {});

    .items as $items
    | [
        ($items[]
        | select(.kind == "Service")
        | select(.metadata.name | endswith("-headless") | not)) as $svc
        | ($items
          | map(select(.kind == "Secret"))
          | map(select(.metadata.labels["freqtrade.io/name"] == $svc.metadata.labels["freqtrade.io/name"]))
          | first) as $secret
        | ($items
          | map(select(.kind == "Ingress"))
          | map(select(.metadata.labels["freqtrade.io/name"] == $svc.metadata.labels["freqtrade.io/name"]))
          | first) as $ing
        | ($secret | if . then secret_json else {} end) as $cfg
        | {
            name: $svc.metadata.labels["freqtrade.io/name"],
            namespace: $svc.metadata.namespace,
            release: $svc.metadata.labels["app.kubernetes.io/instance"],
            service: $svc.metadata.name,
            remote_port: ($svc.spec.ports[0].port // 8080),
            ingress_host: ($ing.spec.rules[0].host // ""),
            username: ($cfg.api_server.username // ""),
            password: ($cfg.api_server.password // ""),
            jwt_secret_key: ($cfg.api_server.jwt_secret_key // ""),
            ws_token: ($cfg.api_server.ws_token // "")
          }
      ]
    | sort_by(.name)
  '
}

ensure_namespace_exists() {
  kubectl get namespace "$NAMESPACE" >/dev/null
}

load_state_json() {
  local file
  file="$(state_file)"
  if [[ -f "$file" ]]; then
    cat "$file"
  else
    echo '[]'
  fi
}

save_state_json() {
  local file
  file="$(state_file)"
  cat >"$file"
}

is_pid_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

render_table() {
  jq -r '
    (["BOT","SERVICE","INGRESS","LOCAL_API_URL","USERNAME","PASSWORD","PF_STATUS"] | @tsv),
    (.[] | [
      .name,
      .service,
      (.ingress_host // ""),
      (.local_api_url // ""),
      (.username // ""),
      (.password // ""),
      (.port_forward_status // "stopped")
    ] | @tsv)
  '
}

attach_state() {
  local bots_json state_json
  bots_json="$1"
  state_json="$2"
  if [[ -z "$state_json" ]]; then
    state_json='[]'
  fi
  jq -cn --argjson bots "$bots_json" --argjson state "$state_json" '
    $bots
    | map(
        . as $bot
        | ($state | map(select(.name == $bot.name)) | first // {}) as $s
        | . + {
            local_port: ($s.local_port // null),
            local_api_url: (
              if ($s.local_port // null) then
                "http://127.0.0.1:\($s.local_port)"
              else
                ""
              end
            ),
            port_forward_status: (
              if ($s.pid // null) then $s.status // "unknown" else "stopped" end
            ),
            pid: ($s.pid // null),
            log_file: ($s.log_file // "")
          }
      )
  '
}

cmd_list() {
  local bots_json state_json
  ensure_namespace_exists
  bots_json="$(discover_bots_json)"
  state_json="$(refresh_state_json)"
  attach_state "$bots_json" "$state_json" | render_table | column -t -s $'\t'
}

refresh_state_json() {
  local current
  current="$(load_state_json)"

  if [[ -z "$current" || "$current" == "[]" ]]; then
    echo '[]'
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local pid status
    pid="$(jq -r '.pid // empty' <<<"$entry")"
    if is_pid_running "$pid"; then
      status="running"
    else
      status="stopped"
    fi
    jq -cn --arg entry "$entry" --arg status "$status" '$entry | fromjson | . + {status: $status}' >>"$tmp_file"
  done < <(jq -c '.[]' <<<"$current")

  if [[ -s "$tmp_file" ]]; then
    jq -s -c '.' "$tmp_file"
  else
    echo '[]'
  fi
  rm -f "$tmp_file"
}

start_port_forward() {
  local name service remote_port local_port log_file pid
  name="$1"
  service="$2"
  remote_port="$3"
  local_port="$4"
  log_file="$5"

  setsid bash -lc "exec kubectl port-forward -n '$NAMESPACE' 'svc/$service' '${local_port}:${remote_port}' --address '$ADDRESS'" >"$log_file" 2>&1 </dev/null &
  pid=$!

  for _ in $(seq 1 30); do
    if ! is_pid_running "$pid"; then
      break
    fi
    if grep -q "Forwarding from" "$log_file" 2>/dev/null; then
      printf '%s' "$pid"
      return 0
    fi
    sleep 1
  done

  if is_pid_running "$pid"; then
    kill "$pid" >/dev/null 2>&1 || true
  fi
  echo "Failed to start port-forward for $name. Check $log_file" >&2
  return 1
}

cmd_start() {
  local bots_json current_state next_port state_entries
  ensure_namespace_exists
  bots_json="$(discover_bots_json)"
  current_state="$(refresh_state_json)"
  next_port="$BASE_PORT"
  state_entries='[]'

  while IFS= read -r bot; do
    [[ -z "$bot" ]] && continue
    local name service remote_port existing pid log_file local_port status
    name="$(jq -r '.name' <<<"$bot")"
    service="$(jq -r '.service' <<<"$bot")"
    remote_port="$(jq -r '.remote_port' <<<"$bot")"
    existing="$(jq -c --arg name "$name" 'map(select(.name == $name)) | first // {}' <<<"$current_state")"
    pid="$(jq -r '.pid // empty' <<<"$existing")"
    status="$(jq -r '.status // empty' <<<"$existing")"
    local_port="$(jq -r '.local_port // empty' <<<"$existing")"
    log_file="$(jq -r '.log_file // empty' <<<"$existing")"

    if [[ -n "$pid" && "$status" == "running" ]]; then
      state_entries="$(jq -cn --argjson entries "$state_entries" --argjson entry "$existing" '$entries + [$entry]')"
      continue
    fi

    if [[ -z "$local_port" || "$local_port" == "null" ]]; then
      while jq -e --argjson port "$next_port" 'map(select(.local_port == $port)) | length > 0' <<<"$state_entries" >/dev/null; do
        next_port=$((next_port + 1))
      done
      local_port="$next_port"
      next_port=$((next_port + 1))
    fi

    if [[ -z "$log_file" ]]; then
      mkdir -p "$STATE_DIR"
      log_file="$STATE_DIR/$(state_key)-${name}.log"
    fi

    pid="$(start_port_forward "$name" "$service" "$remote_port" "$local_port" "$log_file")"
    state_entries="$(jq -cn \
      --argjson entries "$state_entries" \
      --arg name "$name" \
      --arg service "$service" \
      --arg remote_port "$remote_port" \
      --arg local_port "$local_port" \
      --arg pid "$pid" \
      --arg log_file "$log_file" \
      '$entries + [{
        name: $name,
        service: $service,
        remote_port: $remote_port,
        local_port: $local_port,
        pid: $pid,
        log_file: $log_file,
        status: "running"
      }]' )"
  done < <(jq -c '.[]' <<<"$bots_json")

  printf '%s\n' "$state_entries" | save_state_json
  cmd_list
}

cmd_stop() {
  local current_state new_state
  current_state="$(load_state_json)"
  new_state='[]'

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    local pid
    pid="$(jq -r '.pid // empty' <<<"$entry")"
    if is_pid_running "$pid"; then
      kill "$pid" >/dev/null 2>&1 || true
    fi
  done < <(jq -c '.[]' <<<"$current_state")

  printf '%s\n' "$new_state" | save_state_json
  echo "Stopped managed port-forwards for namespace $NAMESPACE"
}

cmd_status() {
  cmd_list
}

main() {
  require_tool kubectl
  require_tool jq
  require_tool column

  local command="${1:-}"
  case "$command" in
    list)
      cmd_list
      ;;
    start)
      cmd_start
      ;;
    stop)
      cmd_stop
      ;;
    status)
      cmd_status
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
