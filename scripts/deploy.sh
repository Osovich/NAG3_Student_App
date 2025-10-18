#!/bin/bash

# Deployment Script for Student App
# Usage: ./deploy.sh [test|production]

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
NAMESPACE_TEST="student-app-staging"
NAMESPACE_PROD="student-app"

# Function to display usage
usage() {
    echo "Usage: $0 [test|production]"
    echo "  test       - Deploy to test environment"
    echo "  production - Deploy to production environment"
    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${GREEN}Checking prerequisites...${NC}"
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}Google Cloud SDK is not installed.${NC}"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl is not installed.${NC}"
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites check passed!${NC}"
}

# Function to build and push Docker images
build_and_push_images() {
    local environment=$1
    local image_tag=${2:-latest}
    
    echo -e "${GREEN}Building and pushing Docker images...${NC}"
    
    # Build frontend image
    echo -e "${YELLOW}Building frontend image...${NC}"
    docker build -t gcr.io/$PROJECT_ID/student-app-frontend:$image_tag ./frontend
    docker push gcr.io/$PROJECT_ID/student-app-frontend:$image_tag
    
    # Build backend image
    echo -e "${YELLOW}Building backend image...${NC}"
    docker build -t gcr.io/$PROJECT_ID/student-app-backend:$image_tag ./backend
    docker push gcr.io/$PROJECT_ID/student-app-backend:$image_tag
    
    echo -e "${GREEN}Images built and pushed successfully!${NC}"
}

# Function to deploy to test environment
deploy_test() {
    echo -e "${GREEN}Deploying to test environment...${NC}"
    
    # Get cluster credentials
    gcloud container clusters get-credentials $CLUSTER_NAME_TEST --zone=$ZONE
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE_TEST --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy MongoDB
    echo -e "${YELLOW}Deploying MongoDB...${NC}"
    kubectl apply -f k8s/mongodb-deployment.yaml -n $NAMESPACE_TEST
    
    # Wait for MongoDB to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n $NAMESPACE_TEST
    
    # Deploy backend
    echo -e "${YELLOW}Deploying backend...${NC}"
    kubectl apply -f k8s/backend-deployment.yaml -n $NAMESPACE_TEST
    
    # Deploy frontend
    echo -e "${YELLOW}Deploying frontend...${NC}"
    kubectl apply -f k8s/frontend-deployment.yaml -n $NAMESPACE_TEST
    
    # Deploy ingress
    echo -e "${YELLOW}Deploying ingress...${NC}"
    kubectl apply -f k8s/ingress.yaml -n $NAMESPACE_TEST
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/student-app-backend -n $NAMESPACE_TEST
    kubectl wait --for=condition=available --timeout=300s deployment/student-app-frontend -n $NAMESPACE_TEST
    
    echo -e "${GREEN}Test deployment completed!${NC}"
    echo -e "${YELLOW}Test environment is available at:${NC}"
    kubectl get ingress -n $NAMESPACE_TEST
}

# Function to deploy to production environment
deploy_production() {
    echo -e "${GREEN}Deploying to production environment...${NC}"
    
    # Get cluster credentials
    gcloud container clusters get-credentials $CLUSTER_NAME_PROD --zone=$ZONE
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE_PROD --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy all resources
    echo -e "${YELLOW}Deploying all resources...${NC}"
    kubectl apply -f k8s/ -n $NAMESPACE_PROD
    
    # Deploy monitoring
    echo -e "${YELLOW}Deploying monitoring stack...${NC}"
    kubectl apply -f monitoring/ -n $NAMESPACE_PROD
    
    # Wait for deployments to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/student-app-backend -n $NAMESPACE_PROD
    kubectl wait --for=condition=available --timeout=300s deployment/student-app-frontend -n $NAMESPACE_PROD
    
    echo -e "${GREEN}Production deployment completed!${NC}"
    echo -e "${YELLOW}Production environment is available at:${NC}"
    kubectl get ingress -n $NAMESPACE_PROD
}

# Function to run health checks
run_health_checks() {
    local namespace=$1
    
    echo -e "${GREEN}Running health checks...${NC}"
    
    # Check pod status
    echo -e "${YELLOW}Checking pod status...${NC}"
    kubectl get pods -n $namespace
    
    # Check service status
    echo -e "${YELLOW}Checking service status...${NC}"
    kubectl get services -n $namespace
    
    # Check ingress status
    echo -e "${YELLOW}Checking ingress status...${NC}"
    kubectl get ingress -n $namespace
    
    echo -e "${GREEN}Health checks completed!${NC}"
}

# Main script logic
main() {
    local environment=$1
    
    if [ -z "$environment" ]; then
        usage
    fi
    
    check_prerequisites
    
    case $environment in
        "test")
            echo -e "${GREEN}Starting test deployment...${NC}"
            build_and_push_images "test" "test-$(date +%Y%m%d-%H%M%S)"
            deploy_test
            run_health_checks $NAMESPACE_TEST
            ;;
        "production")
            echo -e "${GREEN}Starting production deployment...${NC}"
            build_and_push_images "production" "prod-$(date +%Y%m%d-%H%M%S)"
            deploy_production
            run_health_checks $NAMESPACE_PROD
            ;;
        *)
            echo -e "${RED}Invalid environment: $environment${NC}"
            usage
            ;;
    esac
    
    echo -e "${GREEN}Deployment completed successfully!${NC}"
}

# Run main function with all arguments
main "$@"
