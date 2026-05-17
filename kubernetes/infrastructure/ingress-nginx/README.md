# ingress-nginx

Cluster service deployed by ArgoCD. To enable, add the manifests/Helm chart references here. ArgoCD will create the `ingress-nginx` namespace automatically (per the ApplicationSet syncOption `CreateNamespace=true`).
