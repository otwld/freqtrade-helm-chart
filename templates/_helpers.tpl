{{/*
Expand the chart name.
*/}}
{{- define "freqtrade.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "freqtrade.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
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
{{- define "freqtrade.labels" -}}
helm.sh/chart: {{ include "freqtrade.chart" . }}
app.kubernetes.io/name: {{ include "freqtrade.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "freqtrade.selectorLabels" -}}
app.kubernetes.io/name: {{ include "freqtrade.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Service account name.
*/}}
{{- define "freqtrade.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "freqtrade.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Return true when the release is a long-running controller.
*/}}
{{- define "freqtrade.mode.isStateful" -}}
{{- if or (eq .Values.mode.type "trade") (eq .Values.mode.type "dryRun") (eq .Values.mode.type "webserver") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Return true when freqUI should be considered active.
*/}}
{{- define "freqtrade.ui.isEnabled" -}}
{{- if or .Values.ui.enabled (eq .Values.mode.type "webserver") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Return the command passed to the freqtrade CLI.
*/}}
{{- define "freqtrade.mode.command" -}}
{{- if or (eq .Values.mode.type "trade") (eq .Values.mode.type "dryRun") -}}trade
{{- else if eq .Values.mode.type "webserver" -}}webserver
{{- else if eq .Values.mode.type "backtest" -}}backtesting
{{- else if eq .Values.mode.type "hyperopt" -}}hyperopt
{{- else if eq .Values.mode.type "downloadData" -}}download-data
{{- else -}}{{ fail (printf "unsupported mode.type %s" .Values.mode.type) }}
{{- end -}}
{{- end -}}

{{/*
Resolve the effective strategy path.
*/}}
{{- define "freqtrade.strategyPath" -}}
{{- if .Values.strategy.path -}}
{{- .Values.strategy.path -}}
{{- else if eq .Values.strategy.mode "volume" -}}
{{- .Values.strategy.volume.mountPath -}}
{{- else if and (eq .Values.strategy.mode "image") .Values.strategy.image.bakedInPath -}}
{{- .Values.strategy.image.bakedInPath -}}
{{- else -}}
{{- printf "%s/strategies" .Values.persistence.mountPath -}}
{{- end -}}
{{- end -}}

{{/*
Whether the mode requires a strategy name.
*/}}
{{- define "freqtrade.strategy.required" -}}
{{- if and (ne .Values.mode.type "downloadData") (ne .Values.mode.type "webserver") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Return the effective public config with API/UI defaults injected.
*/}}
{{- define "freqtrade.effectivePublicConfig" -}}
{{- $config := deepCopy (.Values.config.public | default dict) -}}
{{- $needsApiServer := or (and .Values.api.enabled (eq (include "freqtrade.mode.isStateful" .) "true")) (eq (include "freqtrade.ui.isEnabled" .) "true") -}}
{{- if $needsApiServer -}}
  {{- $apiServer := deepCopy ((get $config "api_server") | default dict) -}}
  {{- $_ := set $apiServer "enabled" true -}}
  {{- if not (hasKey $apiServer "listen_ip_address") -}}
    {{- $_ := set $apiServer "listen_ip_address" "0.0.0.0" -}}
  {{- end -}}
  {{- if not (hasKey $apiServer "listen_port") -}}
    {{- $_ := set $apiServer "listen_port" .Values.api.containerPort -}}
  {{- end -}}
  {{- if .Values.ui.corsOrigins -}}
    {{- $_ := set $apiServer "CORS_origins" .Values.ui.corsOrigins -}}
  {{- end -}}
  {{- $_ := set $config "api_server" $apiServer -}}
{{- end -}}
{{- toYaml $config -}}
{{- end -}}

{{/*
Generated configmap name.
*/}}
{{- define "freqtrade.publicConfigName" -}}
{{- printf "%s-config" (include "freqtrade.fullname" .) -}}
{{- end -}}

{{/*
Generated private secret name.
*/}}
{{- define "freqtrade.generatedPrivateConfigSecretName" -}}
{{- printf "%s-private-config" (include "freqtrade.fullname" .) -}}
{{- end -}}

{{/*
Resolved private secret name.
*/}}
{{- define "freqtrade.privateConfigSecretName" -}}
{{- if .Values.config.existingSecret -}}
{{- .Values.config.existingSecret -}}
{{- else if and .Values.config.externalSecret.enabled .Values.config.externalSecret.target.name -}}
{{- .Values.config.externalSecret.target.name -}}
{{- else -}}
{{- include "freqtrade.generatedPrivateConfigSecretName" . -}}
{{- end -}}
{{- end -}}

{{/*
Whether a private config secret should be mounted.
*/}}
{{- define "freqtrade.privateConfigEnabled" -}}
{{- if or .Values.config.existingSecret .Values.config.externalSecret.enabled (not (empty .Values.config.sensitive)) -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/*
Resolve the user-data claim name.
*/}}
{{- define "freqtrade.userDataClaimName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-user-data" (include "freqtrade.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the strategy claim name.
*/}}
{{- define "freqtrade.strategyClaimName" -}}
{{- if .Values.strategy.volume.existingClaim -}}
{{- .Values.strategy.volume.existingClaim -}}
{{- else -}}
{{- printf "%s-strategies" (include "freqtrade.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Main container args.
*/}}
{{- define "freqtrade.containerArgs" -}}
- {{ include "freqtrade.mode.command" . | quote }}
- --config
- /etc/freqtrade/config.json
{{- if eq (include "freqtrade.privateConfigEnabled" .) "true" }}
- --config
- /etc/freqtrade/config-private.json
{{- end }}
{{- if eq (include "freqtrade.strategy.required" .) "true" }}
- --strategy
- {{ required "strategy.name is required for the selected mode" .Values.strategy.name | quote }}
- --strategy-path
- {{ include "freqtrade.strategyPath" . | quote }}
{{- end }}
{{- range .Values.mode.extraArgs }}
- {{ . | quote }}
{{- end }}
{{- end -}}

{{/*
Validate key value combinations before rendering resources.
*/}}
{{- define "freqtrade.validate" -}}
{{- if and .Values.config.existingSecret .Values.config.externalSecret.enabled -}}
{{- fail "config.existingSecret and config.externalSecret.enabled are mutually exclusive" -}}
{{- end -}}
{{- if and .Values.ui.enabled (not .Values.api.enabled) -}}
{{- fail "ui.enabled requires api.enabled=true" -}}
{{- end -}}
{{- if and (eq .Values.mode.type "webserver") (not .Values.api.enabled) -}}
{{- fail "mode.type=webserver requires api.enabled=true" -}}
{{- end -}}
{{- if and .Values.ui.ingress.enabled (not (eq (include "freqtrade.ui.isEnabled" .) "true")) -}}
{{- fail "ui.ingress.enabled requires ui.enabled=true or mode.type=webserver" -}}
{{- end -}}
{{- if and .Values.ui.ingress.enabled (not .Values.service.enabled) -}}
{{- fail "ui.ingress.enabled requires service.enabled=true" -}}
{{- end -}}
{{- if and (eq .Values.mode.type "trade") .Values.mode.schedule.enabled -}}
{{- fail "mode.schedule.enabled must be false for trade mode" -}}
{{- end -}}
{{- if and (eq .Values.mode.type "dryRun") .Values.mode.schedule.enabled -}}
{{- fail "mode.schedule.enabled must be false for dryRun mode" -}}
{{- end -}}
{{- if and (eq .Values.mode.type "webserver") .Values.mode.schedule.enabled -}}
{{- fail "mode.schedule.enabled must be false for webserver mode" -}}
{{- end -}}
{{- if and .Values.mode.schedule.enabled (or (eq .Values.mode.type "trade") (eq .Values.mode.type "dryRun")) -}}
{{- fail "scheduled execution is only supported for batch modes" -}}
{{- end -}}
{{- range .Values.ui.corsOrigins }}
  {{- if hasSuffix "/" . -}}
    {{- fail (printf "ui.corsOrigins entries must not end with '/': %s" .) -}}
  {{- end -}}
{{- end -}}
{{- if and .Values.mode.schedule.enabled (not .Values.mode.schedule.cron) -}}
{{- fail "mode.schedule.cron is required when mode.schedule.enabled=true" -}}
{{- end -}}
{{- if and (eq .Values.strategy.mode "initSync") (not .Values.strategy.initSync.enabled) -}}
{{- fail "strategy.initSync.enabled must be true when strategy.mode=initSync" -}}
{{- end -}}
{{- if and (eq (include "freqtrade.strategy.required" .) "true") (not .Values.strategy.name) -}}
{{- fail "strategy.name is required for the selected mode" -}}
{{- end -}}
{{- $publicConfig := .Values.config.public | default dict -}}
{{- $exchangeConfig := (get $publicConfig "exchange") | default dict -}}
{{- $hasOpaqueConfigSource := or .Values.config.existingSecret .Values.config.externalSecret.enabled -}}
{{- $requiresRenderableRuntimeConfig := and (not $hasOpaqueConfigSource) (or (eq (include "freqtrade.ui.isEnabled" .) "true") (eq (include "freqtrade.strategy.required" .) "true")) -}}
{{- if $requiresRenderableRuntimeConfig -}}
  {{- if empty (get $publicConfig "exchange") -}}
    {{- fail "config.public.exchange is required unless config.existingSecret or config.externalSecret supplies the merged runtime config" -}}
  {{- end -}}
  {{- if empty (get $exchangeConfig "name") -}}
    {{- fail "config.public.exchange.name is required unless config.existingSecret or config.externalSecret supplies the merged runtime config" -}}
  {{- end -}}
  {{- if empty (get $publicConfig "stake_currency") -}}
    {{- fail "config.public.stake_currency is required for strategy-driven and UI-enabled releases unless config.existingSecret or config.externalSecret supplies the merged runtime config" -}}
  {{- end -}}
  {{- if empty (get $publicConfig "stake_amount") -}}
    {{- fail "config.public.stake_amount is required for strategy-driven and UI-enabled releases unless config.existingSecret or config.externalSecret supplies the merged runtime config" -}}
  {{- end -}}
  {{- if empty (get $publicConfig "timeframe") -}}
    {{- fail "config.public.timeframe is required for strategy-driven and UI-enabled releases unless config.existingSecret or config.externalSecret supplies the merged runtime config" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Pod annotation block including config checksums.
*/}}
{{- define "freqtrade.podAnnotations" -}}
checksum/config-public: {{ include "freqtrade.effectivePublicConfig" . | fromYaml | toJson | sha256sum }}
{{- if eq (include "freqtrade.privateConfigEnabled" .) "true" }}
checksum/config-private: {{ include "freqtrade.privateConfigChecksum" . }}
{{- end }}
{{- with .Values.podAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Checksum source for the private config.
*/}}
{{- define "freqtrade.privateConfigChecksum" -}}
{{- if .Values.config.existingSecret -}}
{{- printf "existing:%s/%s" .Values.config.existingSecret .Values.config.existingSecretKey | sha256sum -}}
{{- else if .Values.config.externalSecret.enabled -}}
{{- dict "secretName" (include "freqtrade.privateConfigSecretName" .) "secretKey" .Values.config.existingSecretKey "spec" .Values.config.externalSecret | toJson | sha256sum -}}
{{- else -}}
{{- dict "secretName" (include "freqtrade.privateConfigSecretName" .) "secretKey" .Values.config.existingSecretKey "data" .Values.config.sensitive | toJson | sha256sum -}}
{{- end -}}
{{- end -}}

{{/*
Shared volume mounts for the main container.
*/}}
{{- define "freqtrade.volumeMounts" -}}
- name: config
  mountPath: /etc/freqtrade
  readOnly: true
- name: user-data
  mountPath: {{ .Values.persistence.mountPath }}
{{- if eq .Values.strategy.mode "volume" }}
- name: strategies
  mountPath: {{ .Values.strategy.volume.mountPath }}
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Shared volumes for pod specs.
*/}}
{{- define "freqtrade.volumes" -}}
- name: config
  projected:
    sources:
      - configMap:
          name: {{ include "freqtrade.publicConfigName" . }}
          items:
            - key: config.json
              path: config.json
      {{- if eq (include "freqtrade.privateConfigEnabled" .) "true" }}
      - secret:
          name: {{ include "freqtrade.privateConfigSecretName" . }}
          items:
            - key: {{ .Values.config.existingSecretKey }}
              path: config-private.json
      {{- end }}
- name: user-data
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.userDataClaimName" . }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- if eq .Values.strategy.mode "volume" }}
- name: strategies
  persistentVolumeClaim:
    claimName: {{ include "freqtrade.strategyClaimName" . }}
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Generated probes for long-running stateful pods.
*/}}
{{- define "freqtrade.statefulProbes" -}}
{{- if .Values.probes.startup.enabled }}
startupProbe:
  {{- if .Values.api.enabled }}
  httpGet:
    path: /api/v1/ping
    port: http
  {{- else }}
  exec:
    command:
      - /bin/sh
      - -ec
      - pgrep -f "freqtrade" >/dev/null
  {{- end }}
  initialDelaySeconds: {{ .Values.probes.startup.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.startup.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.startup.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.startup.failureThreshold }}
{{- end }}
{{- if .Values.probes.readiness.enabled }}
readinessProbe:
  {{- if .Values.api.enabled }}
  httpGet:
    path: /api/v1/ping
    port: http
  {{- else }}
  exec:
    command:
      - /bin/sh
      - -ec
      - pgrep -f "freqtrade" >/dev/null
  {{- end }}
  initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
  successThreshold: {{ .Values.probes.readiness.successThreshold }}
{{- end }}
{{- if .Values.probes.liveness.enabled }}
livenessProbe:
  {{- if .Values.api.enabled }}
  httpGet:
    path: /api/v1/ping
    port: http
  {{- else }}
  exec:
    command:
      - /bin/sh
      - -ec
      - pgrep -f "freqtrade" >/dev/null
  {{- end }}
  initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
  periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
  timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
  failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
{{- end }}
{{- end -}}

{{/*
Generated strategy sync init container.
*/}}
{{- define "freqtrade.strategyInitContainer" -}}
{{- if and (eq .Values.strategy.mode "initSync") .Values.strategy.initSync.enabled }}
- name: strategy-sync
  image: "{{ .Values.strategy.initSync.image.repository }}:{{ .Values.strategy.initSync.image.tag }}"
  imagePullPolicy: {{ .Values.strategy.initSync.image.pullPolicy }}
  command:
    {{- toYaml .Values.strategy.initSync.command | nindent 4 }}
  {{- with .Values.strategy.initSync.env }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.strategy.initSync.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: user-data
      mountPath: /work
{{- end }}
{{- end -}}
