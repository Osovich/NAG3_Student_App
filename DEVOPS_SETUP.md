# DevOps Pipeline Setup Guide

This guide provides detailed instructions for setting up a complete DevOps pipeline for the Student App using GitHub, Jenkins, Docker, and Google Cloud Platform.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   Jenkins       │    │   Docker        │    │   GCP           │
│   Repository    │───▶│   CI/CD         │───▶│   Containers    │───▶│   Production    │
│   Server        │    │   Server        │    │   Test/Prod     │    │   Server        │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

### Team Requirements
- 4 team members with assigned roles:
  - **DevOps Engineer**: Jenkins setup, GCP configuration
  - **Backend Developer**: API development, testing
  - **Frontend Developer**: UI development, testing
  - **QA Engineer**: Testing, monitoring

### Required Accounts & Services
1. **GitHub Account** with repository access
2. **Google Cloud Platform** account with billing enabled
3. **Jenkins** server (self-hosted or cloud)
4. **Docker Hub** or **Google Container Registry** account

## Step 1: GitHub Repository Setup

### 1.1 Create GitHub Repository
```bash
# Create a new repository on GitHub
# Clone the repository
git clone https://github.com/your-username/student-app.git
cd student-app

# Copy your existing files to the repository
# Add all files
git add .
git commit -m "Initial commit"
git push origin main
```

### 1.2 Set up Branch Protection Rules
1. Go to GitHub repository → Settings → Branches
2. Add rule for `main` branch:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Restrict pushes that create files larger than 100MB

### 1.3 Configure GitHub Secrets
Go to Settings → Secrets and variables → Actions, add:
- `GCP_SA_KEY`: Service account JSON key
- `GCP_PROJECT_ID`: Your GCP project ID
- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password

## Step 2: Google Cloud Platform Setup

### 2.1 Create GCP Project
```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Login to GCP
gcloud auth login

# Create new project
gcloud projects create student-app-project --name="Student App Project"

# Set project as default
gcloud config set project student-app-project

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
```

### 2.2 Create Service Account
```bash
# Create service account
gcloud iam service-accounts create jenkins-sa \
    --description="Service account for Jenkins CI/CD" \
    --display-name="Jenkins Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding student-app-project \
    --member="serviceAccount:jenkins-sa@student-app-project.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding student-app-project \
    --member="serviceAccount:jenkins-sa@student-app-project.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create and download key
gcloud iam service-accounts keys create jenkins-sa-key.json \
    --iam-account=jenkins-sa@student-app-project.iam.gserviceaccount.com
```

### 2.3 Create GKE Clusters
```bash
# Create test cluster
gcloud container clusters create test-cluster \
    --zone=us-central1-a \
    --num-nodes=2 \
    --machine-type=e2-medium \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3

# Create production cluster
gcloud container clusters create production-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-standard-2 \
    --enable-autoscaling \
    --min-nodes=2 \
    --max-nodes=10 \
    --enable-autorepair \
    --enable-autoupgrade
```

### 2.4 Configure Container Registry
```bash
# Configure Docker to use GCR
gcloud auth configure-docker

# Create static IP for production
gcloud compute addresses create student-app-ip --global
```

## Step 3: Jenkins Setup

### 3.1 Install Jenkins
```bash
# On Ubuntu/Debian
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 3.2 Install Required Plugins
1. Go to Jenkins → Manage Jenkins → Manage Plugins
2. Install these plugins:
   - Docker Pipeline
   - Google Kubernetes Engine
   - GitHub Integration
   - Slack Notification
   - Blue Ocean
   - Pipeline

### 3.3 Configure Jenkins Credentials
1. Go to Jenkins → Manage Jenkins → Manage Credentials
2. Add credentials:
   - **GCP Service Account**: Upload the `jenkins-sa-key.json` file
   - **GitHub Token**: Personal access token for GitHub integration
   - **Docker Hub**: Username and password for Docker Hub

### 3.4 Create Jenkins Pipeline
1. Go to Jenkins → New Item
2. Select "Pipeline" and name it "student-app-pipeline"
3. Configure:
   - **Pipeline script from SCM**: Git
   - **Repository URL**: Your GitHub repository URL
   - **Credentials**: GitHub token
   - **Script Path**: Jenkinsfile

## Step 4: Docker Configuration

### 4.1 Update Dockerfiles
The Dockerfiles are already configured in your project. Ensure they include:
- Multi-stage builds for optimization
- Health checks for container monitoring
- Proper security practices (non-root user)

### 4.2 Test Docker Builds Locally
```bash
# Test frontend build
cd frontend
docker build -t student-app-frontend:test .

# Test backend build
cd ../backend
docker build -t student-app-backend:test .

# Test with docker-compose
docker-compose -f docker-compose.test.yml up --build
```

## Step 5: Kubernetes Deployment

### 5.1 Deploy to Test Environment
```bash
# Get cluster credentials
gcloud container clusters get-credentials test-cluster --zone=us-central1-a

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml

# Deploy application
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# Deploy ingress
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get pods -n student-app
kubectl get services -n student-app
```

### 5.2 Deploy to Production Environment
```bash
# Get production cluster credentials
gcloud container clusters get-credentials production-cluster --zone=us-central1-a

# Deploy all resources
kubectl apply -f k8s/

# Set up monitoring
kubectl apply -f monitoring/
```

## Step 6: Monitoring and Logging Setup

### 6.1 Deploy Prometheus and Grafana
```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace

# Access Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Login: admin / prom-operator
```

### 6.2 Configure Application Monitoring
1. Add metrics endpoints to your application
2. Configure Prometheus to scrape metrics
3. Set up Grafana dashboards for visualization
4. Configure alerting rules

## Step 7: CI/CD Pipeline Workflow

### 7.1 Development Workflow
1. **Developer** creates feature branch
2. **Developer** makes changes and commits
3. **Developer** creates pull request
4. **GitHub Actions** runs automated tests
5. **Team** reviews code
6. **Merge** to main branch triggers Jenkins pipeline

### 7.2 Jenkins Pipeline Stages
1. **Checkout**: Get latest code
2. **Build**: Install dependencies and build
3. **Test**: Run unit and integration tests
4. **Docker Build**: Create container images
5. **Docker Test**: Test containers
6. **Push**: Push to container registry
7. **Deploy Test**: Deploy to test environment
8. **Integration Tests**: Run end-to-end tests
9. **Deploy Production**: Deploy to production (main branch only)

## Step 8: Team Responsibilities

### DevOps Engineer
- Maintain Jenkins server
- Monitor GCP resources and costs
- Manage Kubernetes clusters
- Set up monitoring and alerting
- Handle security configurations

### Backend Developer
- Develop API endpoints
- Write unit tests
- Update backend Dockerfile
- Monitor backend performance
- Handle database migrations

### Frontend Developer
- Develop React components
- Write component tests
- Update frontend Dockerfile
- Monitor frontend performance
- Handle UI/UX improvements

### QA Engineer
- Write integration tests
- Set up test automation
- Monitor application health
- Handle bug reports
- Perform manual testing

## Step 9: Security Best Practices

### 9.1 Container Security
- Use non-root users in containers
- Scan images for vulnerabilities
- Keep base images updated
- Use secrets for sensitive data

### 9.2 Kubernetes Security
- Enable RBAC
- Use network policies
- Encrypt secrets
- Regular security updates

### 9.3 GCP Security
- Enable audit logging
- Use IAM roles properly
- Enable VPC firewall rules
- Regular security scans

## Step 10: Monitoring and Maintenance

### 10.1 Daily Monitoring
- Check application health
- Monitor resource usage
- Review logs for errors
- Check CI/CD pipeline status

### 10.2 Weekly Tasks
- Review security updates
- Check backup status
- Update dependencies
- Performance optimization

### 10.3 Monthly Tasks
- Security audit
- Cost optimization
- Capacity planning
- Documentation updates

## Troubleshooting

### Common Issues
1. **Jenkins Build Failures**: Check logs, verify credentials
2. **Docker Build Issues**: Check Dockerfile syntax, dependencies
3. **Kubernetes Deployment Issues**: Check resource limits, health checks
4. **GCP Permission Issues**: Verify service account permissions

### Useful Commands
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check Kubernetes pods
kubectl get pods -n student-app
kubectl describe pod <pod-name> -n student-app

# Check GCP resources
gcloud compute instances list
gcloud container clusters list

# Check Docker images
docker images
docker ps -a
```

## Cost Optimization

### GCP Cost Management
- Use preemptible instances for test environments
- Set up budget alerts
- Use committed use discounts for production
- Regular cleanup of unused resources

### Resource Optimization
- Right-size containers
- Use horizontal pod autoscaling
- Implement proper resource limits
- Monitor and optimize database queries

## Support and Documentation

### Team Communication
- Use Slack for real-time communication
- Set up Jenkins notifications
- Create runbooks for common tasks
- Regular team meetings for updates

### Documentation
- Keep README files updated
- Document deployment procedures
- Create troubleshooting guides
- Maintain architecture diagrams

This setup provides a robust, scalable DevOps pipeline that can handle your team's development needs while maintaining high standards for security, monitoring, and deployment automation.
