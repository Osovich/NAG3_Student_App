# DevOps Pipeline Deployment Guide

## Overview
This guide provides detailed instructions for setting up a complete DevOps pipeline for a team of 4 using:
- **Repository Server**: GitHub
- **CI/CD Server**: Jenkins
- **Test Server**: Docker
- **Production Server**: Docker
- **Host**: Google Cloud Platform

## Prerequisites

### 1. Team Setup (4 Members)
- **DevOps Engineer**: Pipeline setup and maintenance
- **Backend Developer**: API development and testing
- **Frontend Developer**: UI development and testing
- **QA Engineer**: Testing and quality assurance

### 2. Required Accounts and Tools
- GitHub account with repository access
- Google Cloud Platform account with billing enabled
- Jenkins server (can be self-hosted or cloud-based)
- Docker Desktop installed locally
- kubectl CLI tool
- gcloud CLI tool

## Phase 1: GitHub Repository Setup

### 1.1 Create GitHub Repository
```bash
# Initialize repository
git init
git remote add origin https://github.com/your-username/student-app.git

# Add all files
git add .
git commit -m "Initial commit with DevOps pipeline"
git push -u origin main
```

### 1.2 Set up Branch Protection Rules
1. Go to repository Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Restrict pushes that create files

### 1.3 Configure GitHub Secrets
Go to Settings → Secrets and variables → Actions, add:
- `GCP_PROJECT_ID`: Your Google Cloud project ID
- `GCP_SA_KEY`: Service account JSON key (base64 encoded)

## Phase 2: Google Cloud Platform Setup

### 2.1 Create GCP Project
```bash
# Create new project
gcloud projects create your-project-id --name="Student App Project"

# Set project
gcloud config set project your-project-id

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
```

### 2.2 Create Service Account
```bash
# Create service account
gcloud iam service-accounts create student-app-sa \
    --display-name="Student App Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding your-project-id \
    --member="serviceAccount:student-app-sa@your-project-id.iam.gserviceaccount.com" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding your-project-id \
    --member="serviceAccount:student-app-sa@your-project-id.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create student-app-key.json \
    --iam-account=student-app-sa@your-project-id.iam.gserviceaccount.com
```

### 2.3 Set up Google Kubernetes Engine (GKE)
```bash
# Create GKE cluster
gcloud container clusters create student-app-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-medium \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5

# Get cluster credentials
gcloud container clusters get-credentials student-app-cluster \
    --zone=us-central1-a
```

### 2.4 Configure Container Registry
```bash
# Configure Docker to use GCR
gcloud auth configure-docker

# Create namespaces
kubectl apply -f k8s/namespaces.yaml
```

## Phase 3: Jenkins Setup

### 3.1 Install Jenkins
```bash
# Using Docker (recommended for development)
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### 3.2 Configure Jenkins
1. Access Jenkins at `http://localhost:8080`
2. Install suggested plugins
3. Create admin user
4. Install additional plugins:
   - Docker Pipeline
   - Google Kubernetes Engine
   - GitHub Integration

### 3.3 Set up Jenkins Credentials
1. Go to Manage Jenkins → Manage Credentials
2. Add credentials:
   - **GitHub Token**: For repository access
   - **GCP Service Account**: Upload the JSON key file
   - **Docker Registry**: For GCR access

### 3.4 Create Jenkins Pipeline
1. Create new item → Pipeline
2. Configure pipeline:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repository
   - Credentials: GitHub token
   - Script Path: Jenkinsfile

## Phase 4: Docker Configuration

### 4.1 Optimize Docker Images
The project includes optimized Dockerfiles with:
- Multi-stage builds for smaller production images
- Security hardening with non-root users
- Health checks for container monitoring
- Nginx for frontend serving

### 4.2 Build and Test Images
```bash
# Build frontend image
cd frontend
docker build -t gcr.io/your-project-id/student-app-frontend:latest .

# Build backend image
cd ../backend
docker build -t gcr.io/your-project-id/student-app-backend:latest .

# Test locally
docker-compose -f docker-compose.test.yml up --build
```

## Phase 5: Kubernetes Deployment

### 5.1 Deploy to Test Environment
```bash
# Apply test configurations
kubectl apply -f k8s/test/

# Verify deployments
kubectl get pods -n test
kubectl get services -n test
```

### 5.2 Deploy to Production Environment
```bash
# Apply production configurations
kubectl apply -f k8s/production/

# Verify deployments
kubectl get pods -n production
kubectl get services -n production
kubectl get ingress -n production
```

## Phase 6: Team Workflow

### 6.1 Development Workflow
1. **Feature Development**:
   - Create feature branch from `develop`
   - Develop and test locally
   - Push to GitHub

2. **Code Review**:
   - Create pull request to `develop`
   - Team reviews code
   - Automated tests run via GitHub Actions

3. **Testing**:
   - Merge to `develop` triggers test deployment
   - QA team tests in test environment
   - Fix any issues found

4. **Production Release**:
   - Create pull request from `develop` to `main`
   - Team approval required
   - Merge triggers production deployment

### 6.2 Team Responsibilities

#### DevOps Engineer
- Maintain Jenkins pipeline
- Monitor GCP resources and costs
- Handle deployment issues
- Security and compliance

#### Backend Developer
- API development and testing
- Database schema changes
- Performance optimization
- Backend monitoring

#### Frontend Developer
- UI/UX development
- Frontend testing
- Performance optimization
- User experience monitoring

#### QA Engineer
- Test case creation and execution
- Bug reporting and tracking
- Performance testing
- User acceptance testing

## Phase 7: Monitoring and Maintenance

### 7.1 Set up Monitoring
```bash
# Install Prometheus and Grafana
kubectl apply -f monitoring/prometheus.yaml
kubectl apply -f monitoring/grafana.yaml
```

### 7.2 Log Management
```bash
# Set up centralized logging
kubectl apply -f logging/elasticsearch.yaml
kubectl apply -f logging/kibana.yaml
kubectl apply -f logging/fluentd.yaml
```

### 7.3 Backup Strategy
- **Database**: Automated daily backups to GCS
- **Application**: Container image versioning
- **Configuration**: Git repository as source of truth

## Phase 8: Security Considerations

### 8.1 Network Security
- Use VPC for network isolation
- Configure firewall rules
- Enable private Google access

### 8.2 Application Security
- Use HTTPS everywhere
- Implement proper authentication
- Regular security updates
- Container image scanning

### 8.3 Access Control
- Role-based access control (RBAC)
- Service account permissions
- API key management

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check Dockerfile syntax
   - Verify dependencies
   - Review build logs

2. **Deployment Issues**:
   - Check Kubernetes configurations
   - Verify resource limits
   - Review pod logs

3. **Network Issues**:
   - Check service configurations
   - Verify ingress rules
   - Review firewall settings

### Useful Commands
```bash
# Check pod status
kubectl get pods -A

# View pod logs
kubectl logs -f deployment/frontend-prod -n production

# Scale deployment
kubectl scale deployment frontend-prod --replicas=5 -n production

# Check resource usage
kubectl top pods -n production
```

## Cost Optimization

### 8.1 Resource Management
- Use appropriate machine types
- Implement auto-scaling
- Monitor resource usage
- Clean up unused resources

### 8.2 Storage Optimization
- Use appropriate storage classes
- Implement lifecycle policies
- Regular cleanup of old images

## Support and Documentation

### Team Resources
- **Internal Wiki**: Team documentation
- **Slack/Teams**: Communication channel
- **Issue Tracking**: GitHub Issues
- **Code Reviews**: GitHub Pull Requests

### External Resources
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

---

## Quick Start Checklist

- [ ] GitHub repository created and configured
- [ ] GCP project set up with billing enabled
- [ ] GKE cluster created and configured
- [ ] Jenkins server installed and configured
- [ ] Docker images built and tested
- [ ] Kubernetes deployments created
- [ ] Team access and permissions configured
- [ ] Monitoring and logging set up
- [ ] Backup strategy implemented
- [ ] Security measures implemented

This completes the comprehensive DevOps pipeline setup for your team of 4!
