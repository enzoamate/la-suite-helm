{{- define "france-transfert.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "france-transfert.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "france-transfert.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "france-transfert.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: france-transfert
{{- end -}}

{{- define "france-transfert.selectorLabels" -}}
app.kubernetes.io/name: {{ include "france-transfert.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "france-transfert.image" -}}
{{- if .digest -}}
{{- printf "%s@%s" .repository .digest -}}
{{- else -}}
{{- printf "%s:%s" .repository .tag -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "france-transfert.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- required "serviceAccount.name est requis si serviceAccount.create=false" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.initializeServiceAccountName" -}}
{{- if .Values.initialize.serviceAccount.create -}}
{{- default (printf "%s-initialize" (include "france-transfert.fullname" .)) .Values.initialize.serviceAccount.name -}}
{{- else -}}
{{- required "initialize.serviceAccount.name est requis si initialize.serviceAccount.create=false" .Values.initialize.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.secretName" -}}
{{- required "existingSecret doit désigner un Secret existant" .Values.existingSecret -}}
{{- end -}}

{{- define "france-transfert.redisHost" -}}
{{- if .Values.redis.embedded.enabled -}}
{{- printf "%s-redis" (include "france-transfert.fullname" .) -}}
{{- else -}}
{{- required "redis.external.host est requis quand Redis embarqué est désactivé" .Values.redis.external.host -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.s3Endpoint" -}}
{{- if .Values.s3.embedded.enabled -}}
{{- printf "http://%s-s3:8000" (include "france-transfert.fullname" .) -}}
{{- else -}}
{{- required "s3.external.endpoint est requis quand S3 embarqué est désactivé" .Values.s3.external.endpoint -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.clamavHost" -}}
{{- if .Values.clamav.embedded.enabled -}}
{{- printf "%s-clamav" (include "france-transfert.fullname" .) -}}
{{- else -}}
{{- required "clamav.external.host est requis quand ClamAV embarqué est désactivé" .Values.clamav.external.host -}}
{{- end -}}
{{- end -}}

{{- define "france-transfert.storageClass" -}}
{{- if . -}}
storageClassName: {{ . | quote }}
{{- end -}}
{{- end -}}

{{- define "france-transfert.externalDNSAnnotations" -}}
{{- if .Values.routing.externalDNS.enabled }}
external-dns.alpha.kubernetes.io/hostname: {{ .hostname | quote }}
{{- range $key, $value := .Values.routing.externalDNS.annotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}
