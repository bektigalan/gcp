export $ZONE=us-east1-d #change zone
echo $ZONE
export REGION="${ZONE%-*}"
echo $REGION
export $EMAIL=student-04-b9e5211b07da@qwiklabs.net #change email
echo $EMAIL
export PROJECT_ID=$(gcloud config get-value project)
echo $PROJECT_ID
gcloud config set project $PROJECT_ID

gcloud services enable compute.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable recaptchaenterprise.googleapis.com

gcloud compute --project=$PROJECT_ID firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=allow-health-check

gcloud compute firewall-rules create allow-ssh --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0 --target-tags=allow-health-check

gcloud compute instance-templates create lb-backend-template --project=$PROJECT_ID --machine-type=n1-standard-1 --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script=\#\!\ /bin/bash$'\n'sudo\ apt-get\ update$'\n'sudo\ apt-get\ install\ apache2\ -y$'\n'sudo\ a2ensite\ default-ssl$'\n'sudo\ a2enmod\ ssl$'\n'sudo\ su$'\n'vm_hostname=\"\$\(curl\ -H\ \"Metadata-Flavor:Google\"\ \\$'\n'http://metadata.google.internal/computeMetadata/v1/instance/name\)\"$'\n'echo\ \"Page\ served\ from:\ \$vm_hostname\"\ \|\ \\$'\n'tee\ /var/www/html/index.html,enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=$EMAIL --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --region=us-east1 --tags=allow-health-check --create-disk=auto-delete=yes,boot=yes,device-name=lb-backend-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

gcloud beta compute instance-groups managed create lb-backend-example --project=$PROJECT_ID --base-instance-name=lb-backend-example --template=projects/$PROJECT_ID/global/instanceTemplates/lb-backend-template --size=1 --zone=$ZONE --default-action-on-vm-failure=repair --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=PAGELESS && gcloud beta compute instance-groups managed set-autoscaling lb-backend-example --project=$PROJECT_ID --zone=$ZONE --mode=off --min-num-replicas=1 --max-num-replicas=10 --target-cpu-utilization=0.6 --cool-down-period=60

gcloud compute instance-groups set-named-ports lb-backend-example \
--named-ports http:80 \
--zone $ZONE