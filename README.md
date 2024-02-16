# Configure ArgoCD Pipeline with GitlabCI, SOPS Secrets and HelmCharts test

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
 - [GKE Cluster](https://cloud.google.com/kubernetes-engine/?utm_source=google&utm_medium=cpc&utm_campaign=emea-emea-all-en-dr-bkws-all-all-trial-e-gcp-1707574&utm_content=text-ad-none-any-DEV_c-CRE_502312525177-ADGP_Hybrid+%7C+BKWS+-+EXA+%7C+Txt+-+Containers+-+Kubernetes+Engine+-+v3-KWID_43700060411698406-kwd-920676122-userloc_1009991&utm_term=KW_gke-NET_g-PLAC_&&gad_source=1&gclid=CjwKCAiAibeuBhAAEiwAiXBoJBRgCfPA_TJHT81axDZlpDFq5GbReP6GjQN9MDVzlaL2C7g4QAnTixoCrqoQAvD_BwE&gclsrc=aw.ds&hl=en) _(You must to have on gke cluster two namespaces `development/staging` where will be deployed the fastapi applications and postgres statefulset)_
 - [Deployed nginx ingress controller on GKE](https://blog.thecloudside.com/deploying-public-private-nginx-ingress-controllers-with-http-s-loadbalancer-in-gke-dcf894197fb7)
 - [Created gitlab repository](https://gitlab.com/) _(You must to have on repository two branches `development/staging` from where will be triggered your pipeline, for other branches you must to adjust pipeline)_
 - [Already configured Google Artifact Registry for our pipelines](https://cloud.google.com/artifact-registry)
 - Public domain with access to dns hosting dashboard (For example [Cloudflare](https://www.cloudflare.com/))

## Step-by-step configurations

---
Following these steps you will succeed to configure CI/CD pipeline on your cluster.
1. Create namespace argocd
```
$ kubectl create ns argocd
```
2. Deploy ArgoCD with HelmCharts
```
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
3. Disable native ArgoCD tls applying next changes [argocd_docs](https://github.com/argoproj/argo-cd/issues/2953#issuecomment-643042447), [argocd_issue](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/)
```
$ kubectl patch deployment -n argocd argocd-server --patch-file deployment/argocd_configurations/argocd_server_ssl.yaml
```
4. Create ArgoCD Ingress Rule to have access from public
```
$ kubectl apply -f deployment/argocd_configurations/argocd_ingress.yaml
```
_Mention_: Be aware if you have different ingress class name to change it, also to update with your domain name.

5. Create DNS Record with your domain argocd.~~domain.com~~ and load balancer public IP provided by GCloud.

6. Configure admin user on argocd
```
$ argocd admin initial-password --insecure https://argocd.domain.com
```
7. Login with credentials to your ArgoCD dashboard and add gitlab repository
![Untitled (1)](https://github.com/golaneduard/argocd_sops/assets/45820611/75910ac3-55af-4266-9fbb-66d134dd7056)
![CleanShot 2024-02-16 at 22 26 35 2@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/065524d9-958b-4e82-b15e-27e53415fdca)
![CleanShot 2024-02-16 at 22 32 00@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/0078cea4-fc91-421d-8e73-0d085fa06d68)
_Mention_: If you connected with success, you must to have green status on dashboard, like next picture.\
9. Create `GCP Service Account Key` (for the beginning you can delegate full access to project for testing purpose)
![CleanShot 2024-02-16 at 22 27 49@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/830701a0-a9d0-4ce5-a66e-c44b4a3e221c)
![CleanShot 2024-02-16 at 22 29 37@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/225db3a8-7416-42ed-99eb-5ad53acb651b)
![CleanShot 2024-02-16 at 22 30 55@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/6bfbe27a-437f-43d5-8978-de82cf726e66)
10. Create kubernetes secret with `gcp-sa-key`
```
$ kubectl create secret -n argocd generic sa-gcr-key --from-file=my-secret.json
```
10. Create Dockerfile for `argocd repo server plugin container`
```
FROM quay.io/argoproj/argocd:v2.4.11
ARG SOPS_VERSION=v3.7.3

# Switch to root for the ability to perform install
USER root

# Install tools needed for your repo-server to retrieve & decrypt secrets, render manifests
# (e.g. curl, awscli, gpg, sops)
RUN apt-get update && \
    apt-get install -y \
        curl \
        awscli \
        jq \
        gpg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux && \
    chmod +x /usr/local/bin/sops

RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null &&\
    apt-get install apt-transport-https --yes &&\
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list &&\
    apt-get update &&\
    apt-get install helm

# Switch back to non-root user
USER argocd
```
11. Build and push to your container registry
```
$ docker build -t <image:tag> . && docker push <image:tag>
```
12. Create `argocd plugin in configmap` (be careful to provide right `gcp-sa-key-name` in file `argocd_cm_plugin_gcp.yaml`)
```
$ kubectl describe secret sa-gcr-key

# Output
Name:        sa-gcr-key
Namespace:   argocd
Labels:      none
Annotations: none

Type:   Opaque

Data
====
<gcp-sa-key-name.json>: 2392 bytes

$ kubectl apply -f deployment/argocd_configurations/argocd_cm_plugin_gcp.yaml
```
13. Update `argocd-repo-server` to use created plugin from above step (don't forget to update `argocd_repo_server_gcp.yaml` file with custom docker image builded in step #11)
```
kubectl patch deployment -n argocd argocd-repo-server --patch-file deployment/argocd_configurations/argocd_repo_server_gcp.yaml
```
14. Create in Gitlab, two CI/CD variables with name `envVars` and next parameters: _Environment -_ **development/staging**, _Type - file_
```
DOCKER_IMAGE_REGISTRY=<your_google_artifact_registry_address>
ENVIRONMENT=development
DOMAIN=<fastapi.domain.com>
ARGOCD_SERVER_URL=<argocd.domain.com>:443
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=<secure_password>
```
_Mention_: ENVIRONMENT variable is used in pipeline to provide from which path to decrypt secrets\
![CleanShot 2024-02-16 at 22 33 32@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/fb15d3bb-d4b2-47fd-bb52-0cf5866f4a61)
15. Create in Gitlab, CI/CD variable with name `GCR_SERVICE_KEY` and next parameters: _Environment -_ **development/staging**, _Type - file_
```
{
  "type": "service_account",
  "project_id": "project-name",
  "private_key_id": "private-key-id-number",
  "private_key": "-----BEGIN PRIVATE KEY-----PRIVATE_KEY_CONTENT-----END PRIVATE KEY-----\n",
  "client_email": "gcr-nr@project-name.iam.gserviceaccount.com",
  "client_id": "client-id-number",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/gcr-617%40project-name.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```
18. Create GCP `gcp key ring` for sops secrets which will be used for encryption and decryption
```
# First enable kms api on gcp interface
$ gcloud kms keyrings create sops --location global
$ gcloud kms keys create sops-key --location global --keyring sops --purpose encryption
$ gcloud kms keys list --location global --keyring sops
```
19. Deploy postgresql on both namespaces `development/staging`
```
$ helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql
```
_Additional_: bellow will be information how to extract password of postgresql user or how to connect to postgresql instance, therefore to update credentials in `secrets.yaml`
> PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:
> 
> 
> ```
> postgresql.<development/staging>.svc.cluster.local - Read/Write connection
> 
> ```
> 
> To get the password for "postgres" run:
> 
> ```
> export POSTGRES_PASSWORD=$(kubectl get secret --namespace <development/staging> postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
> 
> ```
> 
> To connect to your database run the following command:
> 
> ```
> kubectl run postgresql-client --rm --tty -i --restart='Never' --namespace <development/staging> --image docker.io/bitnami/postgresql:16.1.0-debian-11-r16 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
>   --command -- psql --host postgresql -U postgres -d postgres -p 5432
> 
> > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"
> 
> ```
> 
> To connect to your database from outside the cluster execute the following commands:
> 
> ```
> kubectl port-forward --namespace <development/staging> svc/postgresql 5432:5432 &
> PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
> 
> ```
20. Update credentials and host in files `deployment/helmcharts/fastapi/secrets/<development/staging>/secrets.yaml`
21. Login on localhost with `gcloud auth`
```
gcloud auth application-default login
```
22. Encrypt `deployment/helmcharts/fastapi/secrets/<development/staging>/secrets.yaml` (rename `secrets.yaml` in `secrets_dec.yaml` after encrypt delete them)
```
sops --encrypt --gcp-kms projects/<project-name>/locations/global/keyRings/sops/cryptoKeys/sops-key secrets/<development/staging>/secrets_dec.yaml > secrets/<development/staging>/secrets.yaml
```
23. Push all changes to repository
```
$ git add :/ && git commit -m "$*" && git push
```
24. Create argocd application in web-ui `deployment/argocd_app.yaml`. Create two application with each environment `development/staging` (do not forget to update `name,namespace,targetRevision,repoURL,`)
![CleanShot 2024-02-16 at 22 34 53@2x](https://github.com/golaneduard/argocd_sops/assets/45820611/3b90abbb-7608-4adc-9709-bcc2004f3539)

# Done, if you have encountered any issue at setup, you can open issue in the repository with question, I will do my best to help you !
