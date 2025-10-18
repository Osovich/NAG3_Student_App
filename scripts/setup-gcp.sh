#!/bin/bash

# Google Cloud Platform Setup Script for NAG3 Student App
# This script sets up the GCP infrastructure for the DevOps pipeline

set -e

# Configuration
PROJECT_ID="your-gcp-project-id"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME="nag3-cluster"
SERVICE_ACCOUNT="nag3-service-account"

echo "Setting up Google Cloud Platform infrastructure..."

# Set the project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable dns.googleapis.com

# Create service account
echo "Creating service account..."
gcloud iam service-accounts create $SERVICE_ACCOUNT \
    --display-name="NAG3 Service Account" \
    --description="Service account for NAG3 Student App CI/CD"

# Grant necessary permissions
echo "Granting permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/containerregistry.ServiceAgent"

# Create GKE cluster
echo "Creating GKE cluster..."
gcloud container clusters create $CLUSTER_NAME \
    --zone=$ZONE \
    --num-nodes=3 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade \
    --machine-type=e2-medium \
    --disk-size=20GB \
    --disk-type=pd-standard \
    --enable-network-policy \
    --enable-ip-alias \
    --enable-stackdriver-kubernetes

# Get cluster credentials
echo "Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy application
echo "Deploying application..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/nag3-student-app -n nag3-student-app

# Get external IP
echo "Getting external IP..."
kubectl get service nag3-student-app -n nag3-student-app

echo "Setup complete!"
echo "Your application should be available at the external IP shown above."
