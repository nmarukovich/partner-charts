{{ $fp := .Values.forwardingPlane }}

apiVersion: apps/v1
kind: DaemonSet
spec:
  selector:
    matchLabels:
      app: nsm-{{ $fp }}-plane
  template:
    metadata:
      labels:
        app: nsm-{{ $fp }}-plane
    spec:
      hostPID: true
      hostNetwork: true
      serviceAccount: forward-plane-acc
        {{- if and .Values.imagePullSecrets .Values.imagePullSecrets.repository .Values.imagePullSecrets.username .Values.imagePullSecrets.password }}
      imagePullSecrets:
      - name: kubeslice-image-pull-secret
        {{- end }}
      containers:
        - name: {{ (index .Values $fp).image }}
          securityContext:
            privileged: true
          image: {{ .Values.registry }}/{{ .Values.org }}/{{ (index .Values $fp).image }}:{{ (index .Values $fp).tag }}
          imagePullPolicy: {{ (index .Values $fp).pullPolicy }}
          env:
            - name: INSECURE
              value: {{ .Values.insecure | default false | quote }}
            - name: METRICS_COLLECTOR_ENABLED
              value: {{ .Values.metricsCollectorEnabled | default false | quote }}
            - name: TRACER_ENABLED
              value: {{ .Values.global.JaegerTracing | default false | quote }}
            - name: JAEGER_AGENT_HOST
              value: jaeger.{{ .Release.Namespace }}
            - name: JAEGER_AGENT_PORT
              value: "6831"
            - name: NSM_FORWARDER_SRC_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          volumeMounts:
            - name: workspace
              mountPath: /var/lib/networkservicemesh/
              mountPropagation: Bidirectional
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
          livenessProbe:
            httpGet:
              path: /liveness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
          readinessProbe:
            httpGet:
              path: /readiness
              port: 5555
            initialDelaySeconds: 10
            periodSeconds: 10
            timeoutSeconds: 3
          {{- if (index .Values $fp).resources }}
          resources:
            limits:
              cpu: {{ (index .Values $fp).resources.limitCPU }}
            requests:
              cpu: {{ (index .Values $fp).resources.requestsCPU }}
          {{- end }}
      volumes:
        - hostPath:
            path: /var/lib/networkservicemesh
            type: DirectoryOrCreate
          name: workspace
        - hostPath:
            path: /run/spire/sockets
            type: DirectoryOrCreate
          name: spire-agent-socket
      tolerations:
        - key: "kubeslice.io/node-type"
          operator: "Equal"
          value: "gateway"
          effect: "NoSchedule"
        - key: "kubeslice.io/node-type"
          operator: "Equal"
          value: "gateway"
          effect: "NoExecute"

metadata:
  name: nsm-{{ $fp }}-forwarder
  namespace: {{ .Release.Namespace }}
