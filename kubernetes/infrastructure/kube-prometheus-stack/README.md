# kube-prometheus-stack

Cluster service deployed by ArgoCD. To enable, add the manifests/Helm chart references here. ArgoCD will create the `kube-prometheus-stack` namespace automatically (per the ApplicationSet syncOption `CreateNamespace=true`).
