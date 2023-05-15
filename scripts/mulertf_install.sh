#!/bin/bash

if [ $# -lt 7 ]; then
    echo "I need a minimum of 7 arguments to proceed. REGION, QSS3BucketName, QSS3KeyPrefix, QSS3BucketRegion, EKSCLUSTERNAME, RTFFabricName, OrgID" && exit 1
fi

REGION=$1
QSS3BucketName=$2
QSS3KeyPrefix=$3
QSS3BucketRegion=$4
EKSCLUSTERNAME=$5
RTFFabricName=$6
OrgID=$7

KeyPrefix=${QSS3KeyPrefix%?}

RTFCTL_PATH=./rtfctl

#Install jq for easier JSON object parsing
sudo yum -y install jq

MuleSoftRTFLoginCredentials="MuleSoft-RTF-Login-${RTFFabricName}"
MuleSoftRTFLicense="MuleSoft-License-${RTFFabricName}"

ActivationData=$(aws secretsmanager get-secret-value --secret-id $MuleSoftRTFLoginCredentials --region $REGION | jq -r '(.SecretString | fromjson)' | jq -r .ActivationData)
MuleLicenseKeyinbase64=$(aws secretsmanager get-secret-value --secret-id $MuleSoftRTFLicense --region $REGION | jq -r '(.SecretString | fromjson)' | jq -r .RTF_License_Key_inbase64)


#Update kube config to point to the cluster of our choice
aws eks update-kubeconfig --name ${EKSCLUSTERNAME} --region $REGION

#Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
kubectl get svc

# Create Runtime Fabric
PAYLOAD=$(echo \{\"name\":\"$RTFFabricName\"\,\"vendor\":\"eks\"\,\"region\":\"us-east-1\"\})

# Install rtfctl
curl -L https://anypoint.mulesoft.com/runtimefabric/api/download/rtfctl/latest -o rtfctl
chmod +x ./rtfctl

# Validate Runtime Fabric
./rtfctl validate ${ActivationData}

# Install Runtime Fabric
./rtfctl install ${ActivationData}

# Verify Status of Runtime Fabric
./rtfctl status

#Associate environments to Runtime fabric
## Placeholder for code ##

# Update Runtime Fabric with valid MuleSoft license key
./rtfctl apply mule-license ${MuleLicenseKeyinbase64}

## Start by creating the mandatory resources for ALB Ingress Controller in your cluster: ##
kubectl apply -f deploy.yaml
