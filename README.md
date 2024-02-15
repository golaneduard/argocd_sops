# Configure ArgoCD Pipeline with GitlabCI, SOPS Secrets and HelmCharts

---
This repository will help you to configure for your application an CI/CD pipeline with building an docker image and deploying on Kubernetes Cluster.\
This README will explain how to configure CI/CD for an simple FastAPI app which is connecting to PostgreSQL on kubernetes.

## Content

- [Required applications](#required-applications)
- [Required tools](#required-tools)
- [Step-by-step configurations](#step-by-step-configurations)
## Required tools

---
- [GCloud cli](https://cloud.google.com/sdk/docs/install)
- [ArgoCD cli](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [SOPS](https://github.com/getsops/sops)
- [Helm](https://helm.sh/docs/intro/install/)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Docker](https://docs.docker.com/engine/install/)

## Required applications/configurations

---
Before to start our journey you must to have few things already installed and configured: 
 - [GKE Cluster](https://cloud.google.com/kubernetes-engine/?utm_source=google&utm_medium=cpc&utm_campaign=emea-emea-all-en-dr-bkws-all-all-trial-e-gcp-1707574&utm_content=text-ad-none-any-DEV_c-CRE_502312525177-ADGP_Hybrid+%7C+BKWS+-+EXA+%7C+Txt+-+Containers+-+Kubernetes+Engine+-+v3-KWID_43700060411698406-kwd-920676122-userloc_1009991&utm_term=KW_gke-NET_g-PLAC_&&gad_source=1&gclid=CjwKCAiAibeuBhAAEiwAiXBoJBRgCfPA_TJHT81axDZlpDFq5GbReP6GjQN9MDVzlaL2C7g4QAnTixoCrqoQAvD_BwE&gclsrc=aw.ds&hl=en)
 - [Deployed nginx ingress controller on GKE](https://blog.thecloudside.com/deploying-public-private-nginx-ingress-controllers-with-http-s-loadbalancer-in-gke-dcf894197fb7)
 - [Created gitlab repository](https://gitlab.com/)
 - Public domain with access to dns hosting dashboard (For example [Cloudflare](https://www.cloudflare.com/))

## Step-by-step configurations

---
Following these steps you will succeed to configure CI/CD pipeline on your cluster.
1. Create namespace argocd
```
kubectl create ns argocd
```
2. Deploy ArgoCD with HelmCharts
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
3. Disable native ArgoCD tls applying next changes [argocd_docs](https://github.com/argoproj/argo-cd/issues/2953#issuecomment-643042447), [argocd_issue](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/)
```
kubectl patch deployment -n argocd argocd-server --patch-file deployment/argocd_configurations/argocd_server_ssl.yaml
```
4. Create ArgoCD Ingress Rule to have access from public
```
kubectl apply -f deployment/argocd_configurations/argocd_ingress.yaml
```
_Mention_: Be aware if you have different ingress class name to change it, also to update with your domain name.

5. Create DNS Record with your domain argocd.~~domain.com~~ and load balancer public IP provided by GCloud.

6. Configure admin user on argocd
```
argocd admin initial-password --insecure https://argocd.domain.com
```
7. Login with credentials to your ArgoCD dashboard and add gitlab repository
![Untitled (1)](https://github.com/golaneduard/argocd_sops/assets/45820611/75910ac3-55af-4266-9fbb-66d134dd7056)
