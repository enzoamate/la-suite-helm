{{- define "messages.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "messages.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "messages.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "messages.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "messages.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: messages
{{- end -}}

{{- define "messages.selectorLabels" -}}
app.kubernetes.io/name: {{ include "messages.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "messages.image" -}}
{{- if .digest -}}
{{- printf "%s@%s" .repository .digest -}}
{{- else -}}
{{- printf "%s:%s" .repository .tag -}}
{{- end -}}
{{- end -}}

{{- define "messages.secretName" -}}
{{- required "existingSecret doit désigner un Secret existant" .Values.existingSecret -}}
{{- end -}}

{{- define "messages.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "messages.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- required "serviceAccount.name est requis si serviceAccount.create=false" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "messages.postgresqlHost" -}}
{{- if eq .Values.postgresql.mode "cnpg" -}}
{{- printf "%s-db-rw" (include "messages.fullname" .) -}}
{{- else -}}
{{- required "postgresql.external.host est requis en mode externe" .Values.postgresql.external.host -}}
{{- end -}}
{{- end -}}

{{- define "messages.postgresqlDatabase" -}}
{{- if eq .Values.postgresql.mode "cnpg" -}}
{{- .Values.postgresql.database -}}
{{- else -}}
{{- required "postgresql.external.database est requis en mode externe" .Values.postgresql.external.database -}}
{{- end -}}
{{- end -}}

{{- define "messages.postgresqlUser" -}}
{{- if eq .Values.postgresql.mode "cnpg" -}}
{{- .Values.postgresql.user -}}
{{- else -}}
{{- required "postgresql.external.user est requis en mode externe" .Values.postgresql.external.user -}}
{{- end -}}
{{- end -}}

{{- define "messages.redisUrl" -}}
{{- if eq .Values.redis.mode "embedded" -}}
{{- printf "redis://%s-redis:6379/0" (include "messages.fullname" .) -}}
{{- else -}}
{{- required "redis.external.url est requis en mode externe" .Values.redis.external.url -}}
{{- end -}}
{{- end -}}

{{- define "messages.celeryBrokerUrl" -}}
{{- if eq .Values.redis.mode "embedded" -}}
{{- printf "redis://%s-redis:6379/1" (include "messages.fullname" .) -}}
{{- else -}}
{{- default .Values.redis.external.url .Values.redis.external.celeryBrokerUrl -}}
{{- end -}}
{{- end -}}

{{- define "messages.opensearchUrl" -}}
{{- if eq .Values.opensearch.mode "embedded" -}}
{{- printf "http://%s-opensearch:9200" (include "messages.fullname" .) -}}
{{- else -}}
{{- required "opensearch.external.url est requis en mode externe" .Values.opensearch.external.url -}}
{{- end -}}
{{- end -}}

{{- define "messages.s3ImportsEndpoint" -}}
{{- if eq .Values.s3.mode "embedded" -}}
{{- default (printf "http://%s-s3:%v" (include "messages.fullname" .) .Values.s3.embedded.s3Port) .Values.s3.imports.endpoint -}}
{{- else -}}
{{- default .Values.s3.external.importsEndpoint .Values.s3.imports.endpoint | required "s3.external.importsEndpoint est requis en mode externe" -}}
{{- end -}}
{{- end -}}

{{- define "messages.s3BlobsEndpoint" -}}
{{- if eq .Values.s3.mode "embedded" -}}
{{- default (printf "http://%s-s3:%v" (include "messages.fullname" .) .Values.s3.embedded.s3Port) .Values.s3.blobs.endpoint -}}
{{- else -}}
{{- default .Values.s3.external.blobsEndpoint .Values.s3.blobs.endpoint | required "s3.external.blobsEndpoint est requis en mode externe" -}}
{{- end -}}
{{- end -}}

{{- define "messages.storageClass" -}}
{{- with . }}
storageClassName: {{ . | quote }}
{{- end }}
{{- end -}}

{{- define "messages.storageSecretEnv" -}}
- name: STORAGE_MESSAGE_IMPORTS_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "messages.secretName" . }}
      key: {{ .Values.secretKeys.s3ImportsAccessKey }}
- name: STORAGE_MESSAGE_IMPORTS_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "messages.secretName" . }}
      key: {{ .Values.secretKeys.s3ImportsSecretKey }}
- name: STORAGE_MESSAGE_BLOBS_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "messages.secretName" . }}
      key: {{ .Values.secretKeys.s3BlobsAccessKey }}
- name: STORAGE_MESSAGE_BLOBS_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "messages.secretName" . }}
      key: {{ .Values.secretKeys.s3BlobsSecretKey }}
{{- end -}}
