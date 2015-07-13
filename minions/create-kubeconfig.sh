#!/bin/bash


mkdir -p /srv/kubernetes/kube-proxy
kube_proxy_token=$(etcdctl get /keys/kube-proxy-token)
kube_proxy_kubeconfig_file="/srv/kubernetes/kube-proxy/kubeconfig"
cat > "${kube_proxy_kubeconfig_file}" <<EOF
apiVersion: v1
kind: Config
users:
- name: kube-proxy
  user:
    token: ${kube_proxy_token}
clusters:
- name: local
  cluster:
    insecure-skip-tls-verify: true
contexts:
- context:
    cluster: local
    user: kube-proxy
  name: service-account-context
current-context: service-account-context
EOF

mkdir -p /srv/kubernetes/kubelet
kubelet_token=$(etcdctl get /keys/kubelet-token)
kubelet_kubeconfig_file="/srv/kubernetes/kubelet/kubeconfig"

kubelet_auth_file="/srv/kubernetes/kubelet/kubernetes_auth"
(umask u=rw,go= ; echo "{\"BearerToken\": \"$kubelet_token\", \"Insecure\": true }" > $kubelet_auth_file)

cat > "${kubelet_kubeconfig_file}" <<EOF
apiVersion: v1
kind: Config
users:
- name: kubelet
  user:
    token: ${kubelet_token}
clusters:
- name: local
  cluster:
    insecure-skip-tls-verify: true
contexts:
- context:
    cluster: local
    user: kubelet
  name: service-account-context
current-context: service-account-context
EOF
