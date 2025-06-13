{{/*
Expand the name of the chart.
*/}}
{{- define "bss.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bss.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bss.chart" -}}
{{- printf "%s-%s" .Values.nameOverride .Values.image.tag | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bss.labels" -}}
helm.sh/chart: {{ include "bss.chart" . }}
{{ include "bss.selectorLabels" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ default .Chart.AppVersion .Values.image.tag | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bss.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bss.name" . }}
app.kubernetes.io/instance: {{ default .Release.Name .Values.nameOverride }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "bss.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bss.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
