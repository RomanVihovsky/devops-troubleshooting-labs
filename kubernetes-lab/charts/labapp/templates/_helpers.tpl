{{/* Names */}}
{{- define "labapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "labapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "labapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "labapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "labapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "labapp.labels" -}}
helm.sh/chart: {{ include "labapp.chart" . }}
{{ include "labapp.selectorLabels" . }}
app.kubernetes.io/version: {{ include "labapp.imageTag" . | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: kubernetes-lab
{{- with .Values.component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
{{- end }}

{{- define "labapp.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion | toString }}
{{- end }}

{{- define "labapp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "labapp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "labapp.secretName" -}}
{{- default (include "labapp.fullname" .) .Values.secrets.name }}
{{- end }}

{{- define "labapp.headlessName" -}}
{{- printf "%s-headless" (include "labapp.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "labapp.headlessEnabled" -}}
{{- if or .Values.headless.enabled (eq .Values.app.peers.discovery "dns") }}true{{ end }}
{{- end }}

{{/* Fail early on values that can never work. */}}
{{- define "labapp.validate" -}}
{{- $s := .Values.secrets }}
{{- if not (has $s.source (list "none" "existingSecret" "sealedSecret" "externalSecret")) }}
{{- fail (printf "secrets.source must be none, existingSecret, sealedSecret or externalSecret (got %q)" $s.source) }}
{{- end }}
{{- if and $s.env (eq $s.source "none") }}
{{- fail "secrets.env is set but secrets.source is none: pick existingSecret, sealedSecret or externalSecret" }}
{{- end }}
{{- if eq $s.source "sealedSecret" }}
{{- if not $s.sealedSecret.encryptedData }}
{{- fail "secrets.source=sealedSecret needs secrets.sealedSecret.encryptedData (kubeseal output)" }}
{{- end }}
{{- if not (has $s.sealedSecret.scope (list "strict" "namespace-wide" "cluster-wide")) }}
{{- fail "secrets.sealedSecret.scope must be strict, namespace-wide or cluster-wide" }}
{{- end }}
{{- end }}
{{- if and (eq $s.source "externalSecret") (not (or $s.externalSecret.data $s.externalSecret.dataFrom)) }}
{{- fail "secrets.source=externalSecret needs secrets.externalSecret.data or dataFrom" }}
{{- end }}
{{- end }}

{{/*
Non-secret labapp settings (the <fullname> ConfigMap). Always-present keys document the defaults;
the rest appear only when switched on. app.settings wins over everything.
*/}}
{{- define "labapp.settings" -}}
{{- $a := .Values.app }}
{{- $s := dict }}
{{- $_ := set $s "APP_NAME" (default (include "labapp.fullname" .) $a.name) }}
{{- $_ := set $s "PORT" ($a.port | int64 | toString) }}
{{- $_ := set $s "LOG_LEVEL" $a.logLevel }}
{{- $_ := set $s "LOG_FORMAT" $a.logFormat }}
{{- $_ := set $s "STORAGE_BACKEND" $a.storage }}
{{- $_ := set $s "SHUTDOWN_MODE" $a.shutdown.mode }}
{{- $_ := set $s "SHUTDOWN_DELAY_SECONDS" ($a.shutdown.delaySeconds | int64 | toString) }}
{{- $_ := set $s "SHUTDOWN_TIMEOUT_SECONDS" ($a.shutdown.timeoutSeconds | int64 | toString) }}
{{- $_ := set $s "WORKER_THREADS" ($a.workerThreads | int64 | toString) }}
{{- $_ := set $s "READY_CHECK_DEPENDENCIES" ($a.readyCheckDependencies | toString) }}
{{- with $a.bindAddress }}{{ $_ := set $s "BIND_ADDRESS" . }}{{ end }}
{{- with $a.greeting }}{{ $_ := set $s "GREETING" . }}{{ end }}
{{- with $a.basePath }}{{ $_ := set $s "BASE_PATH" . }}{{ end }}
{{- with $a.allowedHosts }}{{ $_ := set $s "ALLOWED_HOSTS" (join "," .) }}{{ end }}
{{- with $a.requiredEnv }}{{ $_ := set $s "REQUIRED_ENV" (join "," .) }}{{ end }}
{{- with $a.logFile }}{{ $_ := set $s "LOG_FILE" . }}{{ end }}
{{- with $a.maintenanceFile }}{{ $_ := set $s "MAINTENANCE_FILE" . }}{{ end }}
{{- if $a.warmupSeconds }}{{ $_ := set $s "WARMUP_SECONDS" ($a.warmupSeconds | int64 | toString) }}{{ end }}
{{- if $a.cacheMB }}
{{- $_ := set $s "CACHE_MB" ($a.cacheMB | int64 | toString) }}
{{- $_ := set $s "CACHE_WARMUP" $a.cacheWarmup }}
{{- end }}
{{- if $a.diskCacheMB }}{{ $_ := set $s "DISK_CACHE_MB" ($a.diskCacheMB | int64 | toString) }}{{ end }}
{{- if $a.indexerWorkers }}{{ $_ := set $s "INDEXER_WORKERS" ($a.indexerWorkers | int64 | toString) }}{{ end }}
{{- if $a.hashIterations }}{{ $_ := set $s "HASH_ITERATIONS" ($a.hashIterations | int64 | toString) }}{{ end }}
{{- if ne ($a.maxUploadMB | int64) 64 }}{{ $_ := set $s "MAX_UPLOAD_MB" ($a.maxUploadMB | int64 | toString) }}{{ end }}
{{- if $a.errorRate }}{{ $_ := set $s "ERROR_RATE" ($a.errorRate | toString) }}{{ end }}
{{- if $a.autoMigrate }}{{ $_ := set $s "AUTO_MIGRATE" "true" }}{{ end }}
{{- if $a.healthCheckDependencies }}{{ $_ := set $s "HEALTH_CHECK_DEPENDENCIES" "true" }}{{ end }}
{{- with $a.redis.host }}
{{- $_ := set $s "REDIS_HOST" . }}
{{- $_ := set $s "REDIS_PORT" ($a.redis.port | int64 | toString) }}
{{- if $a.redis.db }}{{ $_ := set $s "REDIS_DB" ($a.redis.db | int64 | toString) }}{{ end }}
{{- with $a.redis.username }}{{ $_ := set $s "REDIS_USERNAME" . }}{{ end }}
{{- end }}
{{- with $a.database.url }}{{ $_ := set $s "DATABASE_URL" . }}{{ end }}
{{- with $a.upstream.url }}
{{- $_ := set $s "UPSTREAM_URL" . }}
{{- $_ := set $s "UPSTREAM_TIMEOUT_SECONDS" ($a.upstream.timeoutSeconds | toString) }}
{{- if $a.upstream.required }}{{ $_ := set $s "UPSTREAM_REQUIRED" "true" }}{{ end }}
{{- end }}
{{- with $a.upstream.host }}{{ $_ := set $s "UPSTREAM_HOST" . }}{{ end }}
{{- if ne $a.peers.discovery "none" }}
{{- $_ := set $s "PEER_DISCOVERY" $a.peers.discovery }}
{{- if eq $a.peers.discovery "dns" }}
{{- $_ := set $s "PEER_SERVICE" (default (include "labapp.headlessName" .) $a.peers.service) }}
{{- else }}
{{- $sel := printf "app.kubernetes.io/name=%s,app.kubernetes.io/instance=%s" (include "labapp.name" .) .Release.Name }}
{{- $_ := set $s "PEER_SELECTOR" (default $sel $a.peers.selector) }}
{{- end }}
{{- end }}
{{- with $a.credentialsSecret }}{{ $_ := set $s "CREDENTIALS_SECRET" . }}{{ end }}
{{- if .Values.config.file.enabled }}
{{- $_ := set $s "CONFIG_FILE" (printf "%s/%s" (trimSuffix "/" .Values.config.file.mountPath) .Values.config.file.name) }}
{{- end }}
{{- if .Values.persistence.enabled }}{{ $_ := set $s "DATA_DIR" .Values.persistence.mountPath }}{{ end }}
{{- if .Values.secrets.mountAsFiles }}
{{- range $setting, $key := .Values.secrets.env }}
{{- $_ := set $s (printf "%s_FILE" $setting) (printf "%s/%s" (trimSuffix "/" $.Values.secrets.mountPath) $key) }}
{{- end }}
{{- end }}
{{- range $k, $v := $a.settings }}{{ $_ := set $s $k (toString $v) }}{{ end }}
{{- range $k := keys $s | sortAlpha }}
{{ $k }}: {{ index $s $k | quote }}
{{- end }}
{{- end }}

{{/* Container env: downward API + secretKeyRefs + extraEnv (env beats envFrom). */}}
{{- define "labapp.env" -}}
{{- if .Values.app.downwardAPI }}
- name: POD_NAME
  valueFrom: {fieldRef: {fieldPath: metadata.name}}
- name: POD_NAMESPACE
  valueFrom: {fieldRef: {fieldPath: metadata.namespace}}
- name: POD_IP
  valueFrom: {fieldRef: {fieldPath: status.podIP}}
- name: NODE_NAME
  valueFrom: {fieldRef: {fieldPath: spec.nodeName}}
{{- end }}
{{- if not .Values.secrets.mountAsFiles }}
{{- range $setting, $key := .Values.secrets.env }}
- name: {{ $setting }}
  valueFrom:
    secretKeyRef:
      name: {{ include "labapp.secretName" $ }}
      key: {{ $key }}
{{- end }}
{{- end }}
{{- with .Values.app.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "labapp.envFrom" -}}
- configMapRef:
    name: {{ include "labapp.fullname" . }}
{{- with .Values.app.envFrom }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/* httpGet probe: (list <probe values> <root>) */}}
{{- define "labapp.probe" -}}
{{- $p := index . 0 }}
{{- $root := index . 1 }}
httpGet:
  path: {{ $p.path }}
  port: {{ $root.Values.probes.port }}
  scheme: {{ $root.Values.probes.scheme }}
{{- with omit $p "enabled" "path" }}
{{ toYaml . }}
{{- end }}
{{- end }}
