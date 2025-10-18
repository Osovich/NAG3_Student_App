#!/bin/bash

# Deployment script for NAG3 Student App
# Usage: ./deploy.sh [environment] [version]

set -e

ENVIRONMENT=${1:-test}
VERSION=${2:-latest}
PROJECT_ID="your-gcp-project-id"
REGISTRY="gcr.io"

echo "Deploying NAG3 Student App..."
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"

# Validate environment
if [[ "$ENVIRONMENT" != "test" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "Error: Environment must be 'test', 'staging', or 'production'"
    exit 1
fi

# Set cluster context based on environment
case $ENVIRONMENT in
    "test")
        CLUSTER="test-cluster"
        ZONE="us-central1-a"
        ;;
    "staging")
        CLUSTER="staging-cluster"
        ZONE="us-central1-b"
        ;;
    "production")
        CLUSTER="prod-cluster"
        ZONE="us-central1-c"
        ;;
esac

echo "Configuring kubectl for $CLUSTER in $ZONE..."

# Get cluster credentials
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE

# Update image in deployment
echo "Updating deployment with image $REGISTRY/$PROJECT_ID/nag3-student-app:$VERSION..."

kubectl set image deployment/nag3-student-app \
    nag3-student-app=$REGISTRY/$PROJECT_ID/nag3-student-app:$VERSION \
    -n nag3-student-app

# Wait for rollout
echo "Waiting for rollout to complete..."
kubectl rollout status deployment/nag3-student-app -n nag3-student-app --timeout=300s

# Verify deployment
echo "Verifying deployment..."
kubectl get pods -n nag3-student-app
kubectl get svc -n nag3-student-app

# Health check
echo "Performing health check..."
SERVICE_IP=$(kubectl get svc nag3-student-app -n nag3-student-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -n "$SERVICE_IP" ]; then
    echo "Service IP: $SERVICE_IP"
    echo "Testing health endpoint..."
    curl -f http://$SERVICE_IP/health || echo "Health check failed"
else
    echo "No external IP found. Checking internal service..."
    kubectl port-forward svc/nag3-student-app 8080:80 -n nag3-student-app &
    sleep 5
    curl -f http://localhost:8080/health || echo "Health check failed"
    kill %1
fi

echo "Deployment completed successfully!"
