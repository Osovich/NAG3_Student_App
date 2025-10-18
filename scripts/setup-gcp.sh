#!/bin/bash

# GCP Setup Script for Student App DevOps Pipeline
# Run this script to set up your GCP environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="student-app-project"
REGION="us-central1"
ZONE="us-central1-a"
CLUSTER_NAME_TEST="test-cluster"
CLUSTER_NAME_PROD="production-cluster"
SERVICE_ACCOUNT_NAME="jenkins-sa"

echo -e "${GREEN}Starting GCP setup for Student App DevOps Pipeline...${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Google Cloud SDK is not installed. Please install it first.${NC}"
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}Please authenticate with Google Cloud:${NC}"
    gcloud auth login
fi

# Set default project
echo -e "${GREEN}Setting up project: ${PROJECT_ID}${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${GREEN}Enabling required APIs...${NC}"
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Create service account
echo -e "${GREEN}Creating service account...${NC}"
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --description="Service account for Jenkins CI/CD" \
    --display-name="Jenkins Service Account" \
    --quiet || echo "Service account already exists"

# Grant necessary permissions
echo -e "${GREEN}Granting permissions to service account...${NC}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/container.developer" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.admin" \
    --quiet

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/container.clusterAdmin" \
    --quiet

# Create and download service account key
echo -e "${GREEN}Creating service account key...${NC}"
gcloud iam service-accounts keys create jenkins-sa-key.json \
    --iam-account="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --quiet || echo "Key file already exists"

# Create static IP for production
echo -e "${GREEN}Creating static IP address...${NC}"
gcloud compute addresses create student-app-ip --global --quiet || echo "Static IP already exists"

# Create test cluster
echo -e "${GREEN}Creating test cluster...${NC}"
gcloud container clusters create $CLUSTER_NAME_TEST \
    --zone=$ZONE \
    --num-nodes=2 \
    --machine-type=e2-medium \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3 \
    --enable-autorepair \
    --enable-autoupgrade \
    --quiet || echo "Test cluster already exists"

# Create production cluster
echo -e "${GREEN}Creating production cluster...${NC}"
gcloud container clusters create $CLUSTER_NAME_PROD \
    --zone=$ZONE \
    --num-nodes=3 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade \
    --quiet || echo "Production cluster already exists"

# Configure Docker authentication
echo -e "${GREEN}Configuring Docker authentication...${NC}"
gcloud auth configure-docker --quiet

# Create namespaces
echo -e "${GREEN}Creating Kubernetes namespaces...${NC}"
kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace student-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Helm (if not already installed)
if ! command -v helm &> /dev/null; then
    echo -e "${GREEN}Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add Prometheus Helm repository
echo -e "${GREEN}Setting up monitoring stack...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus and Grafana
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.adminPassword=admin123 \
    --quiet

echo -e "${GREEN}GCP setup completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add the service account key (jenkins-sa-key.json) to Jenkins credentials"
echo "2. Update the PROJECT_ID in your configuration files"
echo "3. Deploy your application using the provided Kubernetes manifests"
echo "4. Access Grafana at: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "5. Login to Grafana with admin/admin123"

echo -e "${GREEN}Setup complete! Your GCP environment is ready for the DevOps pipeline.${NC}"
