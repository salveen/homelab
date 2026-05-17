# cloudnative-pg

Cluster service deployed by ArgoCD. To enable, add the manifests/Helm chart references here. ArgoCD will create the `cloudnative-pg` namespace automatically (per the ApplicationSet syncOption `CreateNamespace=true`).
