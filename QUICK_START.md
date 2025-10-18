# Quick Start Guide - DevOps Pipeline Setup

## 🚀 30-Minute Setup for Team of 4

### Prerequisites Checklist
- [ ] GitHub account with repository access
- [ ] Google Cloud Platform account with billing enabled
- [ ] Docker Desktop installed
- [ ] kubectl and gcloud CLI tools installed

## Step 1: GitHub Repository Setup (5 minutes)

### 1.1 Create Repository
```bash
# Clone your existing repository
git clone https://github.com/your-username/student-app.git
cd student-app

# Add DevOps files (already created)
git add .
git commit -m "Add DevOps pipeline configuration"
git push origin main
```

### 1.2 Configure GitHub Secrets
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add these secrets:
   - `GCP_PROJECT_ID`: `your-gcp-project-id`
   - `GCP_SA_KEY`: `your-service-account-json-key`

## Step 2: Google Cloud Platform Setup (10 minutes)

### 2.1 Create Project and Enable APIs
```bash
# Set your project ID
export PROJECT_ID="your-project-id"

# Create project (if not exists)
gcloud projects create $PROJECT_ID

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable compute.googleapis.com
```

### 2.2 Create GKE Cluster
```bash
# Create cluster
gcloud container clusters create student-app-cluster \
    --zone=us-central1-a \
    --num-nodes=2 \
    --machine-type=e2-small \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3

# Get credentials
gcloud container clusters get-credentials student-app-cluster \
    --zone=us-central1-a
```

### 2.3 Create Service Account
```bash
# Create service account
gcloud iam service-accounts create student-app-sa \
    --display-name="Student App Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:student-app-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

# Create and download key
gcloud iam service-accounts keys create student-app-key.json \
    --iam-account=student-app-sa@$PROJECT_ID.iam.gserviceaccount.com
```

## Step 3: Deploy to Kubernetes (10 minutes)

### 3.1 Create Namespaces
```bash
# Apply namespace configuration
kubectl apply -f k8s/namespaces.yaml
```

### 3.2 Deploy Test Environment
```bash
# Deploy test environment
kubectl apply -f k8s/test/

# Check deployment status
kubectl get pods -n test
kubectl get services -n test
```

### 3.3 Deploy Production Environment
```bash
# Deploy production environment
kubectl apply -f k8s/production/

# Check deployment status
kubectl get pods -n production
kubectl get services -n production
```

## Step 4: Configure Jenkins (5 minutes)

### 4.1 Install Jenkins
```bash
# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### 4.2 Configure Jenkins Pipeline
1. Access Jenkins at `http://localhost:8080`
2. Install suggested plugins
3. Create admin user
4. Create new pipeline job:
   - Name: `student-app-pipeline`
   - Type: Pipeline
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repository
   - Script Path: `Jenkinsfile`

## Step 5: Team Access Setup (5 minutes)

### 5.1 GitHub Team Setup
1. Go to repository → Settings → Manage access
2. Add team members with appropriate permissions:
   - **DevOps Engineer**: Admin access
   - **Backend Developer**: Write access
   - **Frontend Developer**: Write access
   - **QA Engineer**: Read access

### 5.2 GCP Access Setup
```bash
# Add team members to project
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:devops@yourcompany.com" \
    --role="roles/owner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:backend@yourcompany.com" \
    --role="roles/developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:frontend@yourcompany.com" \
    --role="roles/developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:qa@yourcompany.com" \
    --role="roles/viewer"
```

## 🎯 Verification Steps

### Check GitHub Actions
1. Go to your repository → Actions tab
2. Verify CI/CD pipeline is running
3. Check for any failures and fix them

### Check Kubernetes Deployments
```bash
# Check all pods
kubectl get pods -A

# Check services
kubectl get services -A

# Check ingress
kubectl get ingress -A
```

### Check Jenkins Pipeline
1. Go to Jenkins dashboard
2. Run the pipeline manually
3. Check build logs for any errors

## 🔧 Common Issues and Solutions

### Issue: GitHub Actions failing
**Solution:**
- Check if secrets are properly set
- Verify GCP service account permissions
- Review workflow logs for specific errors

### Issue: Kubernetes pods not starting
**Solution:**
```bash
# Check pod logs
kubectl logs -f deployment/frontend-test -n test

# Check pod description
kubectl describe pod <pod-name> -n test

# Check resource limits
kubectl top pods -n test
```

### Issue: Jenkins pipeline failing
**Solution:**
- Check Jenkins logs
- Verify Docker daemon is running
- Check GCP credentials in Jenkins

## 📊 Monitoring Setup

### Basic Monitoring Commands
```bash
# Check resource usage
kubectl top pods -A
kubectl top nodes

# Check pod status
kubectl get pods -A -o wide

# Check service endpoints
kubectl get endpoints -A
```

### Access Application
```bash
# Get external IPs
kubectl get services -A

# Test frontend (replace with actual IP)
curl http://<frontend-ip>

# Test backend (replace with actual IP)
curl http://<backend-ip>/health
```

## 🚨 Emergency Contacts

### Team Responsibilities
- **DevOps Engineer**: Infrastructure issues, deployment problems
- **Backend Developer**: API issues, database problems
- **Frontend Developer**: UI issues, user experience problems
- **QA Engineer**: Testing issues, quality problems

### Escalation Path
1. Team member handles routine issues
2. Escalate to team lead if needed
3. Escalate to management for critical issues

## 📈 Next Steps

### Week 1
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategies
- [ ] Implement security best practices
- [ ] Train team on new processes

### Week 2
- [ ] Optimize performance
- [ ] Set up cost monitoring
- [ ] Implement automated testing
- [ ] Create runbooks and documentation

### Month 1
- [ ] Review and optimize processes
- [ ] Implement advanced monitoring
- [ ] Set up disaster recovery
- [ ] Plan for scaling

## 🎉 Success Criteria

Your DevOps pipeline is successfully set up when:
- [ ] GitHub Actions are running automatically
- [ ] Jenkins pipeline is working
- [ ] Applications are deployed to Kubernetes
- [ ] Team members can access their respective environments
- [ ] Monitoring is in place
- [ ] Documentation is complete

## 📞 Support

### Internal Support
- Team Slack channel
- GitHub Issues
- Internal documentation

### External Support
- Google Cloud Support
- Kubernetes Community
- Docker Documentation
- Jenkins Documentation

---

**Congratulations!** Your DevOps pipeline is now ready for your team of 4. Follow the detailed guides in `DEPLOYMENT_GUIDE.md` and `TEAM_ROLES.md` for comprehensive setup and team management.
