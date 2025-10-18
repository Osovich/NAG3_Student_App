# NAG3 Student App - DevOps Pipeline

A complete DevOps pipeline demonstration using GitHub, Jenkins, Docker, and Google Cloud Platform.

## 🏗️ Architecture

- **Repository Server**: GitHub
- **CI/CD Server**: Jenkins
- **Test Server**: Docker
- **Production Server**: Docker
- **Host**: Google Cloud Platform

## 📋 Prerequisites

### Team Requirements (4 members)
1. **DevOps Engineer**: Jenkins setup, GCP configuration
2. **Backend Developer**: Application development, testing
3. **Frontend Developer**: UI/UX, integration testing
4. **QA Engineer**: Testing, quality assurance

### Tools Required
- Docker Desktop
- Node.js 18+
- Google Cloud SDK
- kubectl
- Git

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/your-org/nag3-student-app.git
cd nag3-student-app
npm install
```

### 2. Local Development
```bash
# Development mode
npm run dev

# Production mode
npm start

# Run tests
npm test
```

### 3. Docker Development
```bash
# Build and run with Docker Compose
docker-compose up app-dev

# Build production image
docker build -t nag3-student-app .
docker run -p 3000:3000 nag3-student-app
```

## 🔧 Setup Instructions

### GitHub Repository Setup

1. **Create Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/your-org/nag3-student-app.git
   git push -u origin main
   ```

2. **Configure Branch Protection**
   - Go to Settings → Branches
   - Add rule for `main` branch
   - Require pull request reviews
   - Require status checks

3. **Set up Secrets**
   - Go to Settings → Secrets and variables → Actions
   - Add: `GCP_SA_KEY`, `GCP_PROJECT_ID`, `SLACK_WEBHOOK`

### Jenkins Setup

1. **Install Jenkins**
   ```bash
   # Using Docker
   docker run -d -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts
   ```

2. **Install Required Plugins**
   - GitHub Integration
   - Docker Pipeline
   - Google Kubernetes Engine
   - Blue Ocean (optional)

3. **Configure Credentials**
   - Add GitHub token
   - Add GCP service account key
   - Add Docker registry credentials

4. **Create Pipeline Job**
   - New Item → Pipeline
   - Configure SCM: GitHub
   - Script Path: `Jenkinsfile`

### Google Cloud Platform Setup

1. **Create Project**
   ```bash
   gcloud projects create your-project-id
   gcloud config set project your-project-id
   ```

2. **Enable APIs**
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```

3. **Run Setup Script**
   ```bash
   chmod +x scripts/setup-gcp.sh
   ./scripts/setup-gcp.sh
   ```

## 🔄 CI/CD Pipeline Flow

### Development Workflow

1. **Feature Development**
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git add .
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

2. **Pull Request**
   - Create PR to `develop` branch
   - Automated tests run
   - Code review required
   - Merge to `develop` triggers test deployment

3. **Production Deployment**
   - Merge `develop` to `main`
   - Automated production deployment
   - Health checks and monitoring

### Pipeline Stages

1. **Code Quality**
   - Linting
   - Security scanning
   - Dependency audit

2. **Testing**
   - Unit tests
   - Integration tests
   - Coverage reporting

3. **Build**
   - Docker image creation
   - Security scanning
   - Registry push

4. **Deploy**
   - Test environment
   - Production environment
   - Health checks

## 📊 Monitoring and Logging

### Health Checks
- Application: `GET /health`
- Kubernetes: Liveness and readiness probes
- Load balancer health checks

### Logging
- Application logs via stdout
- Kubernetes logs via `kubectl logs`
- Stackdriver integration

### Monitoring
- CPU and memory usage
- Request metrics
- Error rates
- Response times

## 🛠️ Team Responsibilities

### DevOps Engineer
- Jenkins configuration
- GCP infrastructure
- Pipeline maintenance
- Security and compliance

### Backend Developer
- Application development
- API design
- Database integration
- Performance optimization

### Frontend Developer
- UI/UX development
- Integration testing
- User experience
- Accessibility

### QA Engineer
- Test automation
- Quality assurance
- Performance testing
- User acceptance testing

## 🔒 Security Best Practices

- Non-root containers
- Read-only filesystems
- Security scanning
- Secret management
- Network policies
- RBAC configuration

## 📈 Scaling

### Horizontal Pod Autoscaler
- CPU-based scaling
- Memory-based scaling
- Custom metrics

### Load Balancing
- GCP Load Balancer
- Health checks
- SSL termination

## 🚨 Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   # Check Jenkins logs
   # Verify Docker build
   # Check dependencies
   ```

2. **Deployment Issues**
   ```bash
   # Check pod status
   kubectl get pods -n nag3-student-app
   
   # Check logs
   kubectl logs -f deployment/nag3-student-app -n nag3-student-app
   ```

3. **Service Issues**
   ```bash
   # Check service status
   kubectl get svc -n nag3-student-app
   
   # Check ingress
   kubectl get ingress -n nag3-student-app
   ```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
