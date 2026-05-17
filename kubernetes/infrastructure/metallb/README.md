# metallb

Cluster service deployed by ArgoCD. To enable, add the manifests/Helm chart references here. ArgoCD will create the `metallb` namespace automatically (per the ApplicationSet syncOption `CreateNamespace=true`).
