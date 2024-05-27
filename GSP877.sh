export $REGION1=us-east1 #change region
echo $REGION1
export $ZONE=us-east1-d #change zone
echo $ZONE
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

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$EMAIL \
    --role=roles/iam.serviceAccountUser

gcloud beta compute instance-groups managed create lb-backend-example --project=$PROJECT_ID --base-instance-name=lb-backend-example --size=1 --template=lb-backend-template --zone=us-east1-d --list-managed-instances-results=PAGELESS --no-force-update-on-repair