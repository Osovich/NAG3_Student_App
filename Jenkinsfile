pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'gcr.io'
        PROJECT_ID = 'your-gcp-project-id'
        IMAGE_NAME = 'nag3-student-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        GCP_CREDENTIALS = credentials('gcp-service-account-key')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Checked out code from ${env.BRANCH_NAME}"
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'test-results.xml'
                    publishCoverage adapters: [jacocoAdapter('coverage.xml')], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                }
            }
        }
        
        stage('Code Quality') {
            steps {
                sh 'npm audit --audit-level moderate'
                // Add ESLint if needed
                // sh 'npm run lint'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}")
                    docker.image("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}").tag("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:latest")
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'gcp-service-account') {
                        docker.image("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:latest").push()
                    }
                }
            }
        }
        
        stage('Deploy to Test Environment') {
            steps {
                script {
                    sh """
                        gcloud auth activate-service-account --key-file=\$GCP_CREDENTIALS
                        gcloud config set project \$PROJECT_ID
                        gcloud container clusters get-credentials test-cluster --zone=us-central1-a
                        
                        # Update deployment with new image
                        kubectl set image deployment/nag3-student-app nag3-student-app=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}
                        kubectl rollout status deployment/nag3-student-app
                    """
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                sh """
                    # Wait for deployment to be ready
                    kubectl wait --for=condition=available --timeout=300s deployment/nag3-student-app
                    
                    # Get service URL
                    SERVICE_URL=\$(kubectl get service nag3-student-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                    
                    # Run integration tests
                    npm run test:integration -- --baseUrl=http://\$SERVICE_URL:3000
                """
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh """
                        gcloud container clusters get-credentials prod-cluster --zone=us-central1-a
                        
                        # Update production deployment
                        kubectl set image deployment/nag3-student-app nag3-student-app=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}:${IMAGE_TAG}
                        kubectl rollout status deployment/nag3-student-app
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed!"
            // Send notification to team
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check Jenkins for details.",
                to: "team@company.com"
            )
        }
    }
}
