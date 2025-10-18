# DevOps Pipeline Deployment Guide

## Overview
This guide provides step-by-step instructions for setting up a complete DevOps pipeline for the Student App using:
- **Repository Server**: GitHub
- **CI/CD Server**: Jenkins
- **Test Server**: Docker + Kubernetes
- **Production Server**: Docker + Kubernetes
- **Host**: Google Cloud Platform

## Prerequisites

### 1. GCP Setup
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
```

### 2. Create GCP Resources
```bash
# Create GKE cluster
gcloud container clusters create student-app-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=10

# Get cluster credentials
gcloud container clusters get-credentials student-app-cluster --zone=us-central1-a

# Create static IP for production
gcloud compute addresses create student-app-ip --global
```

### 3. Service Account Setup
```bash
# Create service account
gcloud iam service-accounts create jenkins-sa \
    --display-name="Jenkins Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:jenkins-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:jenkins-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create jenkins-key.json \
    --iam-account=jenkins-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

## Jenkins Setup

### 1. Install Required Plugins
- Docker Pipeline
- Kubernetes CLI
- Google Cloud SDK
- GitHub Integration
- Blue Ocean (optional)

### 2. Configure Jenkins Credentials
1. Go to Jenkins → Manage Jenkins → Manage Credentials
2. Add new credentials:
   - **Kind**: Secret file
   - **ID**: `gcp-service-account-key`
   - **File**: Upload `jenkins-key.json`

### 3. Create Jenkins Pipeline
1. Create new Pipeline job
2. Configure:
   - **Pipeline script from SCM**: Git
   - **Repository URL**: Your GitHub repository
   - **Script Path**: `Jenkinsfile`

## GitHub Repository Setup

### 1. Repository Secrets
Add these secrets to your GitHub repository:
- `GCP_SA_KEY`: Content of jenkins-key.json
- `GCP_PROJECT_ID`: Your GCP project ID

### 2. Branch Protection Rules
1. Go to Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

## Team Workflow

### Development Process
1. **Feature Development**:
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git add .
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

2. **Create Pull Request**:
   - GitHub will automatically run tests
   - Team members review code
   - Merge to `develop` branch

3. **Testing**:
   - Jenkins automatically deploys to test environment
   - Run integration tests
   - Manual testing by QA team

4. **Production Deployment**:
   - Merge `develop` to `main`
   - Jenkins automatically deploys to production
   - Monitor deployment status

### Team Roles and Responsibilities

#### Developer 1: Frontend Lead
- Maintains frontend codebase
- Reviews frontend pull requests
- Manages React component library
- Ensures UI/UX consistency

#### Developer 2: Backend Lead
- Maintains backend API
- Reviews backend pull requests
- Manages database schema
- Ensures API security

#### Developer 3: DevOps Engineer
- Manages Jenkins pipeline
- Monitors infrastructure
- Handles deployments
- Troubleshoots CI/CD issues

#### Developer 4: QA/Testing Lead
- Writes test cases
- Manages test environments
- Performs manual testing
- Monitors application performance

## Environment Configuration

### Test Environment
- **URL**: `https://test.your-domain.com`
- **Database**: MongoDB test instance
- **Monitoring**: Basic logging
- **Auto-deployment**: On every push to `develop`

### Production Environment
- **URL**: `https://your-domain.com`
- **Database**: MongoDB production cluster
- **Monitoring**: Full monitoring stack
- **Auto-deployment**: On merge to `main`

## Monitoring and Alerting

### 1. Application Monitoring
```bash
# Install Prometheus and Grafana
kubectl apply -f k8s/monitoring/
```

### 2. Log Aggregation
```bash
# Install ELK stack for logging
kubectl apply -f k8s/logging/
```

### 3. Alert Rules
- High CPU usage (>80%)
- High memory usage (>90%)
- Application errors (>5% error rate)
- Database connection failures

## Security Best Practices

### 1. Container Security
- Use non-root users in containers
- Regular security scans with Trivy
- Keep base images updated
- Use multi-stage builds

### 2. Network Security
- Use Kubernetes Network Policies
- Enable TLS/SSL for all communications
- Implement proper ingress rules

### 3. Secrets Management
```bash
# Create secrets for production
kubectl create secret generic mongodb-secret \
    --from-literal=uri="mongodb://user:password@mongo:27017/student-app" \
    -n production
```

## Troubleshooting

### Common Issues

#### 1. Jenkins Build Failures
```bash
# Check Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# Verify GCP credentials
gcloud auth list
```

#### 2. Kubernetes Deployment Issues
```bash
# Check pod status
kubectl get pods -n production

# Check pod logs
kubectl logs -f deployment/frontend-prod -n production

# Describe pod for events
kubectl describe pod <pod-name> -n production
```

#### 3. Database Connection Issues
```bash
# Check MongoDB status
kubectl get pods -l app=mongo -n production

# Test database connectivity
kubectl exec -it <mongo-pod> -- mongo --eval "db.adminCommand('ping')"
```

## Performance Optimization

### 1. Resource Limits
- Set appropriate CPU/memory limits
- Use horizontal pod autoscaling
- Implement resource quotas

### 2. Caching Strategy
- Use Redis for session storage
- Implement CDN for static assets
- Enable browser caching

### 3. Database Optimization
- Use connection pooling
- Implement database indexing
- Regular database maintenance

## Backup and Recovery

### 1. Database Backups
```bash
# Create backup job
kubectl apply -f k8s/backup/mongodb-backup.yaml
```

### 2. Application Backups
- Regular container image backups
- Configuration file versioning
- Disaster recovery procedures

## Cost Optimization

### 1. Resource Management
- Use preemptible instances for test environment
- Implement auto-scaling policies
- Regular resource usage review

### 2. Monitoring Costs
- Set up billing alerts
- Use committed use discounts
- Regular cost analysis

## Maintenance Schedule

### Daily
- Monitor application health
- Check error logs
- Review deployment status

### Weekly
- Security updates
- Performance review
- Backup verification

### Monthly
- Infrastructure review
- Cost analysis
- Security audit

## Support and Documentation

### Team Communication
- Use Slack/Teams for daily communication
- Weekly standup meetings
- Monthly retrospective sessions

### Documentation Updates
- Keep deployment docs current
- Update troubleshooting guides
- Maintain runbooks

## Emergency Procedures

### 1. Rollback Process
```bash
# Rollback to previous version
kubectl rollout undo deployment/frontend-prod -n production
kubectl rollout undo deployment/backend-prod -n production
```

### 2. Incident Response
1. Identify the issue
2. Assess impact
3. Implement fix or rollback
4. Post-incident review

### 3. Contact Information
- **DevOps Lead**: [Contact Info]
- **GCP Support**: [Support Portal]
- **Emergency Escalation**: [Manager Contact]

---

## Quick Start Commands

### Initial Setup
```bash
# Clone repository
git clone https://github.com/your-org/student-app.git
cd student-app

# Set up environment
cp env.example .env
# Edit .env with your values

# Deploy to test
kubectl apply -f k8s/test/

# Deploy to production
kubectl apply -f k8s/production/
```

### Daily Operations
```bash
# Check application status
kubectl get pods -n production

# View logs
kubectl logs -f deployment/frontend-prod -n production

# Scale application
kubectl scale deployment frontend-prod --replicas=5 -n production
```

This comprehensive guide should help your team of 4 successfully deploy and maintain the DevOps pipeline for your student application.
