{{/*
Expand the chart name.
*/}}
{{- define "freqtrade.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "freqtrade.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "freqtrade.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart label.
*/}}
{{- define "freqtrade.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "freqtrade.commonLabels" -}}
helm.sh/chart: {{ include "freqtrade.chart" .root }}
app.kubernetes.io/name: {{ include "freqtrade.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
freqtrade.io/component: {{ .instance._component }}
freqtrade.io/name: {{ .instance._name }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "freqtrade.selectorLabels" -}}
app.kubernetes.io/name: {{ include "freqtrade.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
freqtrade.io/component: {{ .instance._component }}
freqtrade.io/name: {{ .instance._name }}
{{- end -}}

{{/*
Service account name.
*/}}
{{- define "freqtrade.serviceAccountName" -}}
{{- if .Values.global.serviceAccount.create -}}
{{- default (include "freqtrade.fullname" .) .Values.global.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.global.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Base defaults applied to every instance.
*/}}
{{- define "freqtrade.instance.baseDefaults" -}}
enabled: true
mode: dryRun
image: {}
command: []
args: []
extraArgs: []
api:
  enabled: true
  port: 8080
  corsOrigins: []
ui:
  enabled: false
service:
  type: ClusterIP
  annotations: {}
ingress:
  enabled: false
  className: ""
  annotations: {}
  host: ""
  path: /
  pathType: Prefix
  tls: []
strategy:
  name: ""
  source:
    type: image
    path: ""
    volume:
      existingClaim: ""
      mountPath: ""
      accessModes:
        - ReadWriteOnce
      size: 5Gi
      storageClassName: ""
      annotations: {}
    initSync:
      enabled: false
      image:
        repository: alpine/git
        tag: "2.47.2"
        pullPolicy: IfNotPresent
        pullSecrets: []
      command: []
      env: []
      envFrom: []
telegram:
  enabled: false
  token: ""
  chatId: ""
  topicId: ""
  authorizedUsers: []
  allowCustomMessages: null
  reload: null
  balanceDustLevel: null
  notificationSettings: {}
  keyboard: []
config:
  public: {}
  secret: {}
  existingSecret: ""
  existingSecretKey: config-private.json
  externalSecret:
    enabled: false
    refreshInterval: 1h
    secretStoreRef:
      name: ""
      kind: ClusterSecretStore
    target:
      name: ""
      creationPolicy: Owner
    data: []
    dataFrom: []
persistence:
  enabled: true
  mountPath: /freqtrade/user_data
  existingClaim: ""
  accessModes:
    - ReadWriteOnce
  size: 20Gi
  storageClassName: ""
  annotations: {}
resources: {}
podSecurityContext: {}
containerSecurityContext: {}
podAnnotations: {}
podLabels: {}
env: []
envFrom: []
initContainers: []
extraContainers: []
extraVolumes: []
extraVolumeMounts: []
nodeSelector: {}
affinity: {}
tolerations: []
topologySpreadConstraints: []
priorityClassName: ""
terminationGracePeriodSeconds: null
lifecycle: {}
probes: {}
networkPolicy: {}
{{- end -}}

{{/*
Normalize the dashboard values.
*/}}
{{- define "freqtrade.normalizeDashboard" -}}
{{- $root := .root -}}
{{- $base := fromYaml (include "freqtrade.instance.baseDefaults" $root) -}}
{{- $defaults := dict "enabled" false "mode" "webserver" "ui" (dict "enabled" true) "api" (dict "enabled" true "port" 8080 "corsOrigins" (list)) -}}
{{- $instance := mergeOverwrite (deepCopy $base) $defaults -}}
{{- $instance = mergeOverwrite $instance (.dashboard | default dict) -}}
{{- $_ := set $instance "_component" "dashboard" -}}
{{- $_ := set $instance "_name" "dashboard" -}}
{{- toYaml $instance -}}
{{- end -}}

{{/*
Normalize a bot definition.
*/}}
{{- define "freqtrade.normalizeBot" -}}
{{- $root := .root -}}
{{- $base := fromYaml (include "freqtrade.instance.baseDefaults" $root) -}}
{{- $instance := mergeOverwrite (deepCopy $base) (.bot | default dict) -}}
{{- $_ := set $instance "_component" "bot" -}}
{{- $_ := set $instance "_name" (required "bots[].name is required" $instance.name) -}}
{{- toYaml $instance -}}
{{- end -}}

{{/*
Instance fullname.
*/}}
{{- define "freqtrade.instance.fullname" -}}
{{- $name := "" -}}
{{- if eq .instance._component "dashboard" -}}
{{- $name = printf "%s-dashboard" (include "freqtrade.fullname" .root) -}}
{{- else -}}
{{- $name = printf "%s-bot-%s" (include "freqtrade.fullname" .root) .instance._name -}}
{{- end -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Instance headless service name.
*/}}
{{- define "freqtrade.instance.headlessServiceName" -}}
{{- printf "%s-headless" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Public API service name.
*/}}
{{- define "freqtrade.instance.apiServiceName" -}}
{{- include "freqtrade.instance.fullname" . -}}
{{- end -}}

{{/*
Config resource names.
*/}}
{{- define "freqtrade.instance.publicConfigName" -}}
{{- printf "%s-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "freqtrade.instance.generatedPrivateConfigSecretName" -}}
{{- printf "%s-private-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "freqtrade.instance.privateConfigSecretName" -}}
{{- if .instance.config.existingSecret -}}
{{- .instance.config.existingSecret -}}
{{- else if and .instance.config.externalSecret.enabled .instance.config.externalSecret.target.name -}}
{{- .instance.config.externalSecret.target.name -}}
{{- else -}}
{{- include "freqtrade.instance.generatedPrivateConfigSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.privateConfigEnabled" -}}
{{- if or .instance.config.existingSecret .instance.config.externalSecret.enabled (not (empty (.instance.config.secret | default dict))) -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.telegramEnabled" -}}
{{- $telegram := .instance.telegram | default dict -}}
{{- if and (eq .instance._component "bot") ($telegram.enabled | default false) -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.telegramSecretName" -}}
{{- printf "%s-telegram-config" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Telegram config rendered as a dedicated secret-backed overlay file.
*/}}
{{- define "freqtrade.instance.telegramConfig" -}}
{{- $telegramValues := .instance.telegram | default dict -}}
{{- $telegram := dict "enabled" true "token" $telegramValues.token "chat_id" $telegramValues.chatId -}}
{{- if $telegramValues.topicId -}}
  {{- $_ := set $telegram "topic_id" $telegramValues.topicId -}}
{{- end -}}
{{- if $telegramValues.authorizedUsers -}}
  {{- $_ := set $telegram "authorized_users" $telegramValues.authorizedUsers -}}
{{- end -}}
{{- if hasKey $telegramValues "allowCustomMessages" -}}
  {{- $_ := set $telegram "allow_custom_messages" $telegramValues.allowCustomMessages -}}
{{- end -}}
{{- if hasKey $telegramValues "reload" -}}
  {{- $_ := set $telegram "reload" $telegramValues.reload -}}
{{- end -}}
{{- if hasKey $telegramValues "balanceDustLevel" -}}
  {{- $_ := set $telegram "balance_dust_level" $telegramValues.balanceDustLevel -}}
{{- end -}}
{{- if $telegramValues.notificationSettings -}}
  {{- $_ := set $telegram "notification_settings" $telegramValues.notificationSettings -}}
{{- end -}}
{{- if $telegramValues.keyboard -}}
  {{- $_ := set $telegram "keyboard" $telegramValues.keyboard -}}
{{- end -}}
{{- dict "telegram" $telegram | toYaml -}}
{{- end -}}

{{/*
PVC names.
*/}}
{{- define "freqtrade.instance.userDataClaimName" -}}
{{- if .instance.persistence.existingClaim -}}
{{- .instance.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-user-data" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.strategyClaimName" -}}
{{- if .instance.strategy.source.volume.existingClaim -}}
{{- .instance.strategy.source.volume.existingClaim -}}
{{- else -}}
{{- printf "%s-strategies" (include "freqtrade.instance.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Whether the instance requires a strategy.
*/}}
{{- define "freqtrade.instance.requiresStrategy" -}}
{{- if eq .instance._component "bot" -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Resolve strategy path.
*/}}
{{- define "freqtrade.instance.strategyPath" -}}
{{- if .instance.strategy.source.path -}}
{{- .instance.strategy.source.path -}}
{{- else if and (eq .instance.strategy.source.type "volume") .instance.strategy.source.volume.mountPath -}}
{{- .instance.strategy.source.volume.mountPath -}}
{{- else -}}
{{- printf "%s/strategies" .instance.persistence.mountPath -}}
{{- end -}}
{{- end -}}

{{/*
Resolve mode command.
*/}}
{{- define "freqtrade.instance.modeCommand" -}}
{{- if eq .instance.mode "webserver" -}}webserver{{- else -}}trade{{- end -}}
{{- end -}}

{{/*
Effective public config with API defaults injected.
*/}}
{{- define "freqtrade.instance.effectiveCorsOrigins" -}}
{{- $origins := .instance.api.corsOrigins | default list -}}
{{- if not (empty $origins) -}}
{{- toYaml $origins -}}
{{- else if and (eq .instance._component "bot") .root.Values.dashboard.enabled .root.Values.dashboard.ingress.enabled .root.Values.dashboard.ingress.host -}}
{{- $host := .root.Values.dashboard.ingress.host -}}
{{- toYaml (list (printf "https://%s" $host) (printf "http://%s" $host)) -}}
{{- else -}}
{{- toYaml (list) -}}
{{- end -}}
{{- end -}}

{{- define "freqtrade.instance.effectivePublicConfig" -}}
{{- $config := deepCopy (.instance.config.public | default dict) -}}
{{- if eq .instance._component "bot" -}}
  {{- if not (hasKey $config "dry_run") -}}
    {{- $_ := set $config "dry_run" (eq .instance.mode "dryRun") -}}
  {{- end -}}
  {{- if not (hasKey $config "initial_state") -}}
    {{- $_ := set $config "initial_state" "running" -}}
  {{- end -}}
{{- end -}}
{{- if or .instance.api.enabled .instance.ui.enabled (eq .instance._component "dashboard") -}}
  {{- $apiServer := deepCopy ((get $config "api_server") | default dict) -}}
  {{- $corsOrigins := include "freqtrade.instance.effectiveCorsOrigins" . | fromYamlArray -}}
  {{- $_ := set $apiServer "enabled" true -}}
  {{- if not (hasKey $apiServer "listen_ip_address") -}}
    {{- $_ := set $apiServer "listen_ip_address" "0.0.0.0" -}}
  {{- end -}}
  {{- if not (hasKey $apiServer "listen_port") -}}
    {{- $_ := set $apiServer "listen_port" .instance.api.port -}}
  {{- end -}}
  {{- if not (empty $corsOrigins) -}}
    {{- $_ := set $apiServer "CORS_origins" $corsOrigins -}}
  {{- end -}}
  {{- $_ := set $config "api_server" $apiServer -}}
{{- end -}}
{{- toYaml $config -}}
{{- end -}}

{{/*
Container args.
*/}}
{{- define "freqtrade.instance.containerArgs" -}}
- {{ include "freqtrade.instance.modeCommand" . | quote }}
- --config
- /etc/freqtrade/config.json
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- --config
- /etc/freqtrade/config-private.json
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- --config
- /etc/freqtrade/config-telegram.json
{{- end }}
{{- if eq (include "freqtrade.instance.requiresStrategy" .) "true" }}
- --strategy
- {{ required (printf "strategy.name is required for bot %s" .instance._name) .instance.strategy.name | quote }}
- --strategy-path
- {{ include "freqtrade.instance.strategyPath" . | quote }}
{{- end }}
{{- range (.instance.extraArgs | default list) }}
- {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Merged pod annotations with config checksums.
*/}}
{{- define "freqtrade.instance.podAnnotations" -}}
{{- $annotations := mergeOverwrite (deepCopy (.root.Values.global.podAnnotations | default dict)) (.instance.podAnnotations | default dict) -}}
{{- $_ := set $annotations "checksum/public-config" (include "freqtrade.instance.effectivePublicConfig" . | sha256sum) -}}
{{- if .instance.config.existingSecret -}}
  {{- $_ := set $annotations "checksum/private-config" (.instance.config.existingSecret | sha256sum) -}}
{{- else if .instance.config.externalSecret.enabled -}}
  {{- $_ := set $annotations "checksum/private-config" (include "freqtrade.instance.privateConfigSecretName" . | sha256sum) -}}
{{- else -}}
  {{- $_ := set $annotations "checksum/private-config" ((toYaml (.instance.config.secret | default dict)) | sha256sum) -}}
{{- end -}}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" -}}
  {{- $_ := set $annotations "checksum/telegram-config" (include "freqtrade.instance.telegramConfig" . | sha256sum) -}}
{{- end -}}
{{- if eq .instance.strategy.source.type "initSync" -}}
  {{- $_ := set $annotations "checksum/strategy-sync" ((toYaml .instance.strategy.source.initSync) | sha256sum) -}}
{{- end -}}
{{- toYaml $annotations -}}
{{- end -}}

{{/*
Render the strategy init container when enabled.
*/}}
{{- define "freqtrade.instance.strategyInitContainer" -}}
{{- if and (eq .instance.strategy.source.type "initSync") .instance.strategy.source.initSync.enabled -}}
{{- $image := mergeOverwrite (deepCopy (.root.Values.global.image | default dict)) (.instance.strategy.source.initSync.image | default dict) -}}
- name: strategy-sync
  image: "{{ $image.repository }}:{{ $image.tag }}"
  imagePullPolicy: {{ $image.pullPolicy }}
  {{- with .instance.strategy.source.initSync.command }}
  command:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .instance.strategy.source.initSync.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .instance.strategy.source.initSync.env }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: user-data
      mountPath: {{ .instance.persistence.mountPath }}
    {{- if eq .instance.strategy.source.type "volume" }}
    - name: strategy-volume
      mountPath: {{ include "freqtrade.instance.strategyPath" . }}
    {{- end }}
{{- end -}}
{{- end -}}

{{/*
Main container volume mounts.
*/}}
{{- define "freqtrade.instance.volumeMounts" -}}
- name: public-config
  mountPath: /etc/freqtrade/config.json
  subPath: config.json
  readOnly: true
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- name: private-config
  mountPath: /etc/freqtrade/config-private.json
  subPath: {{ default "config-private.json" .instance.config.existingSecretKey }}
  readOnly: true
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- name: telegram-config
  mountPath: /etc/freqtrade/config-telegram.json
  subPath: config-telegram.json
  readOnly: true
{{- end }}
- name: user-data
  mountPath: {{ .instance.persistence.mountPath }}
{{- if eq .instance.strategy.source.type "volume" }}
- name: strategy-volume
  mountPath: {{ include "freqtrade.instance.strategyPath" . }}
{{- end }}
{{- with .instance.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Pod volumes.
*/}}
{{- define "freqtrade.instance.volumes" -}}
- name: public-config
  configMap:
    name: {{ include "freqtrade.instance.publicConfigName" . }}
{{- if eq (include "freqtrade.instance.privateConfigEnabled" .) "true" }}
- name: private-config
  secret:
    secretName: {{ include "freqtrade.instance.privateConfigSecretName" . }}
{{- end }}
{{- if eq (include "freqtrade.instance.telegramEnabled" .) "true" }}
- name: telegram-config
  secret:
    secretName: {{ include "freqtrade.instance.telegramSecretName" . }}
{{- end }}
- name: user-data
  {{- if .instance.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.instance.userDataClaimName" . }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- if eq .instance.strategy.source.type "volume" }}
- name: strategy-volume
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.instance.strategyClaimName" . }}
{{- end }}
{{- with .instance.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Stateful probes.
*/}}
{{- define "freqtrade.instance.statefulProbes" -}}
{{- $probes := mergeOverwrite (deepCopy (.root.Values.global.probes | default dict)) (.instance.probes | default dict) -}}
{{- $httpProbe := dict "httpGet" (dict "path" "/api/v1/ping" "port" "http") -}}
{{- $execProbe := dict "exec" (dict "command" (list "/bin/sh" "-ec" "pgrep -f 'freqtrade' >/dev/null")) -}}
{{- $probeAction := ternary $httpProbe $execProbe .instance.api.enabled -}}
{{- if ($probes.startup.enabled | default false) }}
startupProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.startup.initialDelaySeconds | default 10 }}
  periodSeconds: {{ $probes.startup.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probes.startup.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.startup.failureThreshold | default 30 }}
{{- end }}
{{- if ($probes.readiness.enabled | default false) }}
readinessProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.readiness.initialDelaySeconds | default 5 }}
  periodSeconds: {{ $probes.readiness.periodSeconds | default 10 }}
  timeoutSeconds: {{ $probes.readiness.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.readiness.failureThreshold | default 6 }}
  successThreshold: {{ $probes.readiness.successThreshold | default 1 }}
{{- end }}
{{- if ($probes.liveness.enabled | default false) }}
livenessProbe:
  {{- toYaml $probeAction | nindent 2 }}
  initialDelaySeconds: {{ $probes.liveness.initialDelaySeconds | default 30 }}
  periodSeconds: {{ $probes.liveness.periodSeconds | default 15 }}
  timeoutSeconds: {{ $probes.liveness.timeoutSeconds | default 5 }}
  failureThreshold: {{ $probes.liveness.failureThreshold | default 6 }}
{{- end }}
{{- end -}}

{{/*
Validate one instance.
*/}}
{{- define "freqtrade.instance.validate" -}}
{{- $instance := .instance -}}
{{- $privateConfigRef := or $instance.config.existingSecret $instance.config.externalSecret.enabled -}}
{{- $public := $instance.config.public | default dict -}}
{{- $private := $instance.config.secret | default dict -}}
{{- $exchange := (get $public "exchange") | default dict -}}
{{- $pairlists := (get $public "pairlists") | default list -}}
{{- $secretApi := (get $private "api_server") | default dict -}}
{{- $telegram := $instance.telegram | default dict -}}
{{- if and $instance.config.existingSecret $instance.config.externalSecret.enabled -}}
{{- fail (printf "%s: config.existingSecret and config.externalSecret.enabled are mutually exclusive" $instance._name) -}}
{{- end -}}
{{- if eq $instance._component "dashboard" -}}
  {{- if ne $instance.mode "webserver" -}}
    {{- fail "dashboard.mode must be webserver" -}}
  {{- end -}}
  {{- if not $instance.ui.enabled -}}
    {{- fail "dashboard.ui.enabled must be true when dashboard.enabled=true" -}}
  {{- end -}}
  {{- if not $instance.api.enabled -}}
    {{- fail "dashboard.api.enabled must be true when dashboard.enabled=true" -}}
  {{- end -}}
  {{- if ($telegram.enabled | default false) -}}
    {{- fail "dashboard.telegram.enabled is not supported; configure Telegram on bots only" -}}
  {{- end -}}
{{- else -}}
  {{- if and (ne $instance.mode "trade") (ne $instance.mode "dryRun") -}}
    {{- fail (printf "bot %s: mode must be trade or dryRun" $instance._name) -}}
  {{- end -}}
  {{- if not $instance.strategy.name -}}
    {{- fail (printf "bot %s: strategy.name is required" $instance._name) -}}
  {{- end -}}
  {{- if ($telegram.enabled | default false) -}}
    {{- if hasKey $public "telegram" -}}
      {{- fail (printf "bot %s: telegram.enabled cannot be combined with config.public.telegram" $instance._name) -}}
    {{- end -}}
    {{- if hasKey $private "telegram" -}}
      {{- fail (printf "bot %s: telegram.enabled cannot be combined with config.secret.telegram" $instance._name) -}}
    {{- end -}}
    {{- if not $telegram.token -}}
      {{- fail (printf "bot %s: telegram.token is required when telegram.enabled=true" $instance._name) -}}
    {{- end -}}
    {{- if not $telegram.chatId -}}
      {{- fail (printf "bot %s: telegram.chatId is required when telegram.enabled=true" $instance._name) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- if and $instance.ui.enabled (not $instance.api.enabled) -}}
{{- fail (printf "%s: ui.enabled requires api.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.ui.enabled) -}}
{{- fail (printf "%s: ingress.enabled requires ui.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.api.enabled) -}}
{{- fail (printf "%s: ingress.enabled requires api.enabled=true" $instance._name) -}}
{{- end -}}
{{- if and $instance.ingress.enabled (not $instance.ingress.host) -}}
{{- fail (printf "%s: ingress.host is required when ingress.enabled=true" $instance._name) -}}
{{- end -}}
{{- $effectiveCorsOrigins := include "freqtrade.instance.effectiveCorsOrigins" . | fromYamlArray -}}
{{- range $origin := ($effectiveCorsOrigins | default list) }}
  {{- if hasSuffix "/" $origin -}}
    {{- fail (printf "%s: api.corsOrigins entries must not end with '/': %s" $instance._name $origin) -}}
  {{- end -}}
{{- end -}}
{{- if eq $instance.strategy.source.type "initSync" -}}
  {{- if not $instance.strategy.source.initSync.enabled -}}
    {{- fail (printf "bot %s: strategy.source.initSync.enabled must be true when strategy.source.type=initSync" $instance._name) -}}
  {{- end -}}
  {{- if empty ($instance.strategy.source.initSync.command | default list) -}}
    {{- fail (printf "bot %s: strategy.source.initSync.command is required when using initSync" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if and (not $privateConfigRef) (or $instance.api.enabled $instance.ui.enabled (eq $instance._component "dashboard")) -}}
  {{- if not (get $secretApi "username") -}}
    {{- fail (printf "%s: config.secret.api_server.username is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "password") -}}
    {{- fail (printf "%s: config.secret.api_server.password is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "jwt_secret_key") -}}
    {{- fail (printf "%s: config.secret.api_server.jwt_secret_key is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
  {{- if not (get $secretApi "ws_token") -}}
    {{- fail (printf "%s: config.secret.api_server.ws_token is required when api.enabled=true" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if not (get $exchange "name") -}}
  {{- fail (printf "%s: config.public.exchange.name is required" $instance._name) -}}
{{- end -}}
{{- if not (get $public "stake_currency") -}}
  {{- fail (printf "%s: config.public.stake_currency is required" $instance._name) -}}
{{- end -}}
{{- if not (hasKey $public "stake_amount") -}}
  {{- fail (printf "%s: config.public.stake_amount is required" $instance._name) -}}
{{- end -}}
{{- if not (get $public "timeframe") -}}
  {{- fail (printf "%s: config.public.timeframe is required" $instance._name) -}}
{{- end -}}
{{- if ne $instance._component "dashboard" -}}
  {{- if not (get $public "entry_pricing") -}}
    {{- fail (printf "%s: config.public.entry_pricing is required" $instance._name) -}}
  {{- end -}}
  {{- if not (get $public "exit_pricing") -}}
    {{- fail (printf "%s: config.public.exit_pricing is required" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- if empty $pairlists -}}
  {{- fail (printf "%s: config.public.pairlists is required" $instance._name) -}}
{{- end -}}
{{- range $pairlist := $pairlists -}}
  {{- if and (eq (($pairlist.method | default "") | toString) "StaticPairList") (empty ((get $exchange "pair_whitelist") | default list)) -}}
    {{- fail (printf "%s: config.public.exchange.pair_whitelist is required when using StaticPairList" $instance._name) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate the whole chart.
*/}}
{{- define "freqtrade.validateAll" -}}
{{- $names := dict -}}
{{- range $i, $bot := (.Values.bots | default list) -}}
  {{- if ($bot.enabled | default true) -}}
    {{- $name := required (printf "bots[%d].name is required" $i) $bot.name -}}
    {{- if eq $name "dashboard" -}}
      {{- fail "bot name 'dashboard' is reserved" -}}
    {{- end -}}
    {{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" $name) -}}
      {{- fail (printf "bot name %q must be a DNS-1123 compatible label" $name) -}}
    {{- end -}}
    {{- if hasKey $names $name -}}
      {{- fail (printf "duplicate bot name %q" $name) -}}
    {{- end -}}
    {{- $_ := set $names $name true -}}
    {{- $instance := fromYaml (include "freqtrade.normalizeBot" (dict "root" $ "bot" $bot)) -}}
    {{- include "freqtrade.instance.validate" (dict "root" $ "instance" $instance) -}}
  {{- end -}}
{{- end -}}
{{- if .Values.dashboard.enabled -}}
  {{- $dashboard := fromYaml (include "freqtrade.normalizeDashboard" (dict "root" . "dashboard" .Values.dashboard)) -}}
  {{- include "freqtrade.instance.validate" (dict "root" . "instance" $dashboard) -}}
  {{- $jobCfg := $dashboard.dataJobs.downloadData | default dict -}}
  {{- if and $dashboard.dataJobs.enabled $jobCfg.enabled -}}
    {{- if not $dashboard.persistence.enabled -}}
      {{- fail "dashboard.dataJobs.downloadData requires dashboard.persistence.enabled=true" -}}
    {{- end -}}
    {{- if empty ($jobCfg.pairs | default list) -}}
      {{- fail "dashboard.dataJobs.downloadData.pairs must not be empty when enabled" -}}
    {{- end -}}
    {{- if empty ($jobCfg.timeframes | default list) -}}
      {{- fail "dashboard.dataJobs.downloadData.timeframes must not be empty when enabled" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
