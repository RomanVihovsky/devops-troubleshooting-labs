{{- define "labapp.volumeMounts" -}}
{{- if .Values.tmpVolume.enabled }}
- name: tmp
  mountPath: /tmp
{{- end }}
{{- with .Values.app.logFile }}
- name: logs
  mountPath: {{ dir . }}
{{- end }}
{{- if .Values.config.file.enabled }}
{{- $f := .Values.config.file }}
- name: config-file
  {{- if $f.subPath }}
  mountPath: {{ printf "%s/%s" (trimSuffix "/" $f.mountPath) $f.name }}
  subPath: {{ $f.name }}
  {{- else }}
  mountPath: {{ $f.mountPath }}
  {{- end }}
  readOnly: true
{{- end }}
{{- if and .Values.secrets.mountAsFiles (ne .Values.secrets.source "none") }}
- name: secrets
  mountPath: {{ .Values.secrets.mountPath }}
  readOnly: true
{{- end }}
{{- if .Values.persistence.enabled }}
- name: data
  mountPath: {{ .Values.persistence.mountPath }}
{{- end }}
{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "labapp.volumes" -}}
{{- if .Values.tmpVolume.enabled }}
- name: tmp
  emptyDir:
    {{- with .Values.tmpVolume.sizeLimit }}
    sizeLimit: {{ . }}
    {{- end }}
{{- end }}
{{- if .Values.app.logFile }}
- name: logs
  emptyDir: {}
{{- end }}
{{- if .Values.config.file.enabled }}
- name: config-file
  configMap:
    name: {{ include "labapp.fullname" . }}-files
{{- end }}
{{- if and .Values.secrets.mountAsFiles (ne .Values.secrets.source "none") }}
- name: secrets
  secret:
    secretName: {{ include "labapp.secretName" . }}
{{- end }}
{{- if .Values.persistence.enabled }}
- name: data
  persistentVolumeClaim:
    claimName: {{ .Values.persistence.existingClaim | default (include "labapp.fullname" .) }}
{{- end }}
{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end }}
