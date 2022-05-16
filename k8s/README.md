# Docker

## Build

You can replace nerdctl with docker if you don't use containerd.

**Frontend**:
```
nerdctl build --platform=linux/x86_64 -t exo.container-registry.com/exoscale-images/exoscale-order-party-frontend:latest exoscale-order-party-frontend
```

**Backend**:
Set the ENV BACKENDURL if neccessary (will be only updated on build; default is http://exoscale-order-backend.cldsvc.io)

```
nerdctl build --platform=linux/x86_64 -t exo.container-registry.com/exoscale-images/exoscale-order-party-backend:latest exoscale-order-party-backend
```

## Push

```
# Use your email and the key shown in your harbor profile
nerdctl login exo.container-registry.com
```

```
nerdctl push exo.container-registry.com/exoscale-images/exoscale-order-party-frontend:latest
nerdctl push exo.container-registry.com/exoscale-images/exoscale-order-party-backend:latest
```


# Kubernetes

Generate a secret for your container registry (generate secret at *harbor -> your project -> Robot Accounts*):
```
kubectl create secret docker-registry regcred --docker-server=exo.container-registry.com --docker-username=ROBOUSERNAME --docker-password=KEY
```

LEGACY - Done in main.tf - file is created based on input and imported automatically. User for DB need to be "avnadmin" as hardcoded in frontend container.
Create SQL credentials secret (adapt the secret file first...). Don't forget to populate the DB first with the sql file included in the backend code.
```
kubectl create secret generic order-pg-credentials --from-env-file=db-secret.sh
```


Apply the ingress-nginx controller which will create an Exoscale NLB:
```
kubectl apply -f ingress-nginx-controller.yaml
```

Apply the app, creating two deployments and Ingress routes:
```
kubectl apply -f app.yaml
```

Set the DNS of the frontend and backend to the IP of the created Exoscale NLB.

# Terraform

Requires kubectl and psql binary to work

Please generate a terraform.tfvars file with all needed variables
By applying the Terraform script will ask for several required credentials and variables to deploy a working environment.
```
terraform init
terraform apply
```
DNS is now included, as our Domain is in a different Exoscale Organization, we need to specify different API/Secret Key for 



