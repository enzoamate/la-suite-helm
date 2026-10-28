{{- define "grist.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "grist.fullname" -}}
{{- if .Values.fullnameOverride -}}{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else -}}{{ printf "%s-%s" .Release.Name (include "grist.name" .) | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}
{{- define "grist.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
app.kubernetes.io/name: {{ include "grist.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}
{{- define "grist.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grist.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- define "grist.image" -}}
{{- if .digest -}}{{ printf "%s@%s" .repository .digest }}{{- else -}}{{ printf "%s:%s" .repository .tag }}{{- end -}}
{{- end -}}
