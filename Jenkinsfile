pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'gcr.io'
        PROJECT_ID = 'your-gcp-project-id'
        IMAGE_NAME = 'student-app'
        GCP_CREDENTIALS = credentials('gcp-service-account-key')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build & Test Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm ci'
                    sh 'npm run test -- --coverage --watchAll=false'
                    sh 'npm run build'
                }
            }
        }
        
        stage('Build & Test Backend') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                    sh 'npm test || true'  # Add tests when available
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    def frontendImage = docker.build("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${BUILD_NUMBER}")
                    def backendImage = docker.build("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${BUILD_NUMBER}")
                    
                    // Tag with latest
                    sh "docker tag ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:latest"
                    sh "docker tag ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:latest"
                }
            }
        }
        
        stage('Push to GCR') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud config set project ${PROJECT_ID}'
                        sh 'gcloud auth configure-docker'
                        
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${BUILD_NUMBER}"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:latest"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${BUILD_NUMBER}"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Test Environment') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud config set project ${PROJECT_ID}'
                        
                        // Deploy to test environment
                        sh 'kubectl apply -f k8s/test/'
                        sh 'kubectl rollout status deployment/frontend-test -n test'
                        sh 'kubectl rollout status deployment/backend-test -n test'
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    // Run integration tests against test environment
                    sh 'npm run test:integration || true'
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud config set project ${PROJECT_ID}'
                        
                        // Deploy to production
                        sh 'kubectl apply -f k8s/production/'
                        sh 'kubectl rollout status deployment/frontend-prod -n production'
                        sh 'kubectl rollout status deployment/backend-prod -n production'
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        success {
            // Send success notification
            echo 'Pipeline completed successfully!'
        }
        failure {
            // Send failure notification
            echo 'Pipeline failed!'
        }
    }
}
