#!/bin/bash

# Monitoring script for NAG3 Student App
# Usage: ./monitor.sh [environment]

set -e

ENVIRONMENT=${1:-test}

echo "Monitoring NAG3 Student App..."
echo "Environment: $ENVIRONMENT"

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

echo "=== Deployment Status ==="
kubectl get deployment nag3-student-app -n nag3-student-app

echo -e "\n=== Pod Status ==="
kubectl get pods -n nag3-student-app -l app=nag3-student-app

echo -e "\n=== Service Status ==="
kubectl get svc nag3-student-app -n nag3-student-app

echo -e "\n=== Ingress Status ==="
kubectl get ingress nag3-student-app-ingress -n nag3-student-app

echo -e "\n=== HPA Status ==="
kubectl get hpa nag3-student-app-hpa -n nag3-student-app

echo -e "\n=== Recent Events ==="
kubectl get events -n nag3-student-app --sort-by='.lastTimestamp' | tail -10

echo -e "\n=== Resource Usage ==="
kubectl top pods -n nag3-student-app

echo -e "\n=== Application Logs (last 20 lines) ==="
kubectl logs -l app=nag3-student-app -n nag3-student-app --tail=20

echo -e "\n=== Health Check ==="
SERVICE_IP=$(kubectl get svc nag3-student-app -n nag3-student-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -n "$SERVICE_IP" ]; then
    echo "Service IP: $SERVICE_IP"
    echo "Testing health endpoint..."
    curl -s http://$SERVICE_IP/health | jq . || echo "Health check failed or jq not installed"
else
    echo "No external IP found. Using port-forward for health check..."
    kubectl port-forward svc/nag3-student-app 8080:80 -n nag3-student-app &
    PF_PID=$!
    sleep 5
    curl -s http://localhost:8080/health | jq . || echo "Health check failed or jq not installed"
    kill $PF_PID
fi

echo -e "\nMonitoring completed!"
