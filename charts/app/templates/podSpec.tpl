{{- define "app.podLabels" -}}
labels:
  {{- include "app.labels" . | nindent 2 }}
  {{- with .Values.podLabels }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}



{{- define "app.podSpec" -}}
spec:
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "app.serviceAccountName" . }}
  securityContext:
    {{- toYaml .Values.podSecurityContext | nindent 4 }}
  {{- with .Values.initContainers }}
  initContainers:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if or .Values.topologySpreadConstraints .Values.autoscaling.enabled .Values.keda.enabled }}
  topologySpreadConstraints:
  {{- if .Values.topologySpreadConstraints }}
  {{- toYaml .Values.topologySpreadConstraints | nindent 4 }}
  {{- end }}
  {{- if or .Values.autoscaling.enabled .Values.keda.enabled }}
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: ScheduleAnyway
      labelSelector:
        matchLabels:
          app.kubernetes.io/instance: {{ include "app.name" . }}
  {{- end }}
  {{- end }}
  {{- if .Values.priorityClass.enabled }}
  priorityClassName: {{ .Values.priorityClass.name }}
  {{- end }}
  containers:
  {{- with .Values.additionalContainers }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
    - name: {{ .Chart.Name }}
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- with .Values.command}}
      command:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.args}}
      args:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.env }}
      env:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.envFrom }}
      envFrom:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      ports:
      {{- range $port := .Values.ports }}
        - containerPort: {{ $port.num }}
          protocol: TCP
          name: {{ $port.name }}
      {{- end }}
      {{- if .Values.startupProbe }}
      startupProbe:
        initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds | default "60" }}
        {{- if eq .Values.healthcheck "http" }}
        httpGet:
          scheme: {{ .Values.startupProbe.scheme | default "HTTP" | quote }}
          path: {{ .Values.startupProbe.path | default "/" | quote }}
          {{- with .Values.startupProbe.httpHeaders }}
          httpHeaders:
            {{- toYaml . | nindent 14 }}
          {{- end }}
        {{ else }}
        tcpSocket:
        {{- end }}
          port: {{ .Values.startupProbe.port | default "http" }}
      {{- end }} 
      livenessProbe:
        initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds | default "60" }}
        {{- if eq .Values.healthcheck "http" }}
        httpGet:
          scheme: {{ .Values.livenessProbe.scheme | default "HTTP" | quote }}
          path: {{ .Values.livenessProbe.path | default "/" | quote }}
          {{- with .Values.livenessProbe.httpHeaders }}
          httpHeaders:
            {{- toYaml . | nindent 14 }}
          {{- end }}
        {{ else }}
        tcpSocket:
        {{- end }}
          port: {{ .Values.livenessProbe.port | default "http" }}
      readinessProbe:
        initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds | default "60" }}
        {{- if eq .Values.healthcheck "http" }}
        httpGet:
          scheme: {{ .Values.readinessProbe.scheme | default "HTTP" | quote }}
          path: {{ .Values.readinessProbe.path | default "/" | quote }}
          {{- with .Values.readinessProbe.httpHeaders }}
          httpHeaders:
            {{- toYaml . | nindent 14 }}
          {{- end }}
        {{ else }}
        tcpSocket:
        {{- end }}
          port: {{ .Values.readinessProbe.port | default "http" }}
      resources:
        {{- toYaml .Values.resources | nindent 8 }}
      {{- with .Values.volumeMounts }}
      volumeMounts:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      lifecycle:
        {{- toYaml .Values.lifecycle | nindent 8 }}
  {{- with .Values.volumes }}
  volumes:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  affinity:
    podAntiAffinity:
      {{- if or .Values.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution .Values.autoscaling.enabled .Values.keda.enabled }}
      requiredDuringSchedulingIgnoredDuringExecution:
        {{- if .Values.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution }}
        {{- toYaml .Values.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution | nindent 8 }}
        {{- end }} 
        {{- if or .Values.autoscaling.enabled .Values.keda.enabled }}
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - {{ include "app.name" . }}
          topologyKey: kubernetes.io/hostname
        {{- end }}
      {{- end }}
      preferredDuringSchedulingIgnoredDuringExecution:
      {{- toYaml .Values.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution | nindent 8 }}
    {{- with .Values.affinity.podAffinity }}
    podAffinity:
      {{- toYaml . | nindent 6 }}  
    {{- end }}
    {{- with .Values.affinity.nodeAffinity }}
    nodeAffinity:
      {{- toYaml . | nindent 6 }}  
    {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
{{- end -}}
