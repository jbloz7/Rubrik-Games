{{/* Base name for all resources: the release name unless overridden. */}}
{{- define "games.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 52 | trimSuffix "-" -}}
{{- end -}}

{{- define "games.labels" -}}
app.kubernetes.io/name: rubrik-games
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "games.selector" -}}
app.kubernetes.io/name: rubrik-games
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Caddy routes for the menu site: /api/recent/<id> is proxied to each app's recent-games path, everything else is the menu page. */}}
{{- define "games.menuRoutes" -}}
{{- range .Values.apps }}
{{- if .recentPath }}
handle /api/recent/{{ .id }} {
  rewrite * {{ .recentPath }}
  reverse_proxy {{ .upstream }}
}
{{- end }}
{{- end }}
handle {
  root * /srv
  file_server
}
{{- end -}}

{{/* Certificates are only persisted when HTTPS is on and persistence is requested. */}}
{{- define "games.persist" -}}
{{- if and .Values.tls.enabled .Values.persistence.enabled -}}true{{- end -}}
{{- end -}}
