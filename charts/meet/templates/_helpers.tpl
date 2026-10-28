{{- define "meet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meet.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "meet.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "meet.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "meet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: meet
{{- end -}}

{{- define "meet.selectorLabels" -}}
app.kubernetes.io/name: {{ include "meet.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "meet.image" -}}
{{- if .digest -}}
{{- printf "%s@%s" .repository .digest -}}
{{- else -}}
{{- printf "%s:%s" .repository .tag -}}
{{- end -}}
{{- end -}}

{{- define "meet.secretName" -}}
{{- required "existingSecret doit désigner un Secret existant" .Values.existingSecret -}}
{{- end -}}

{{- define "meet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "meet.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- required "serviceAccount.name est requis si serviceAccount.create=false" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "meet.postgresqlHost" -}}
{{- if eq .Values.postgresql.mode "embedded" -}}
{{- printf "%s-postgresql" (include "meet.fullname" .) -}}
{{- else -}}
{{- required "postgresql.external.host est requis en mode externe" .Values.postgresql.external.host -}}
{{- end -}}
{{- end -}}

{{- define "meet.postgresqlDatabase" -}}
{{- if eq .Values.postgresql.mode "embedded" -}}
{{- .Values.postgresql.database -}}
{{- else -}}
{{- required "postgresql.external.database est requis en mode externe" .Values.postgresql.external.database -}}
{{- end -}}
{{- end -}}

{{- define "meet.postgresqlUser" -}}
{{- if eq .Values.postgresql.mode "embedded" -}}
{{- .Values.postgresql.user -}}
{{- else -}}
{{- required "postgresql.external.user est requis en mode externe" .Values.postgresql.external.user -}}
{{- end -}}
{{- end -}}

{{- define "meet.postgresqlPort" -}}
{{- if eq .Values.postgresql.mode "embedded" -}}
{{- .Values.postgresql.port -}}
{{- else -}}
{{- .Values.postgresql.external.port -}}
{{- end -}}
{{- end -}}

{{- define "meet.redisUrl" -}}
{{- if eq .Values.redis.mode "embedded" -}}
{{- printf "redis://%s-redis:6379/1" (include "meet.fullname" .) -}}
{{- else -}}
{{- required "redis.external.url est requis en mode externe" .Values.redis.external.url -}}
{{- end -}}
{{- end -}}

{{- define "meet.celeryBrokerUrl" -}}
{{- if eq .Values.redis.mode "embedded" -}}
{{- printf "redis://%s-redis:6379/0" (include "meet.fullname" .) -}}
{{- else -}}
{{- default .Values.redis.external.url .Values.redis.external.celeryBrokerUrl -}}
{{- end -}}
{{- end -}}

{{- define "meet.livekitEndpoint" -}}
{{- if eq .Values.livekit.mode "embedded" -}}
{{- printf "https://%s" .Values.livekit.host -}}
{{- else -}}
{{- required "livekit.external.endpoint est requis en mode externe" .Values.livekit.external.endpoint -}}
{{- end -}}
{{- end -}}

{{- define "meet.storageClass" -}}
{{- with . }}
storageClassName: {{ . | quote }}
{{- end }}
{{- end -}}

{{- define "meet.secretEnv" -}}
- name: DJANGO_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.djangoSecretKey }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.databasePassword }}
- name: LIVEKIT_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.livekitApiKey }}
- name: LIVEKIT_API_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.livekitApiSecret }}
{{- if .Values.oidc.enabled }}
- name: OIDC_RP_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.oidcClientSecret }}
{{- end }}
{{- if .Values.smtp.enabled }}
- name: DJANGO_EMAIL_HOST_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.smtpPassword }}
{{- end }}
{{- if .Values.media.enabled }}
- name: AWS_S3_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.mediaAccessKey }}
- name: AWS_S3_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.mediaSecretKey }}
{{- end }}
{{- if .Values.advanced.summary.enabled }}
- name: SUMMARY_SERVICE_API_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.summaryApiToken }}
- name: SUMMARY_SERVICE_WEBHOOK_API_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "meet.secretName" . }}
      key: {{ .Values.secretKeys.summaryWebhookApiToken }}
{{- end }}
{{- end -}}
