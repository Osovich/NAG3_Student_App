#!/bin/bash

# Rollback script for NAG3 Student App
# Usage: ./rollback.sh [environment] [revision]

set -e

ENVIRONMENT=${1:-test}
REVISION=${2:-previous}
PROJECT_ID="your-gcp-project-id"

echo "Rolling back NAG3 Student App..."
echo "Environment: $ENVIRONMENT"
echo "Revision: $REVISION"

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

# Rollback deployment
echo "Rolling back deployment..."
kubectl rollout undo deployment/nag3-student-app -n nag3-student-app

# Wait for rollout
echo "Waiting for rollback to complete..."
kubectl rollout status deployment/nag3-student-app -n nag3-student-app --timeout=300s

# Verify rollback
echo "Verifying rollback..."
kubectl get pods -n nag3-student-app
kubectl rollout history deployment/nag3-student-app -n nag3-student-app

# Health check
echo "Performing health check after rollback..."
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

echo "Rollback completed successfully!"
