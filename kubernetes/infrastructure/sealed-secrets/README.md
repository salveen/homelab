# sealed-secrets

Cluster service deployed by ArgoCD. To enable, add the manifests/Helm chart references here. ArgoCD will create the `sealed-secrets` namespace automatically (per the ApplicationSet syncOption `CreateNamespace=true`).
