pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'gcr.io'
        PROJECT_ID = 'your-gcp-project-id'
        IMAGE_NAME = 'student-app'
        GCP_KEY_FILE = credentials('gcp-service-account-key')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm test -- --coverage --watchAll=false'
                        }
                    }
                }
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            sh 'npm test'
                        }
                    }
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    def frontendImage = docker.build("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${env.BUILD_NUMBER}")
                    def backendImage = docker.build("${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${env.BUILD_NUMBER}")
                    
                    // Tag with latest
                    sh "docker tag ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${env.BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:latest"
                    sh "docker tag ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${env.BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:latest"
                }
            }
        }
        
        stage('Docker Test') {
            steps {
                sh 'docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit'
            }
            post {
                always {
                    sh 'docker-compose -f docker-compose.test.yml down'
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud auth configure-docker'
                        
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${env.BUILD_NUMBER}"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${env.BUILD_NUMBER}"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:latest"
                        sh "docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh 'gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS'
                        sh 'gcloud container clusters get-credentials test-cluster --zone=us-central1-a'
                        sh "kubectl set image deployment/student-app-frontend frontend=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${env.BUILD_NUMBER}"
                        sh "kubectl set image deployment/student-app-backend backend=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${env.BUILD_NUMBER}"
                        sh 'kubectl rollout status deployment/student-app-frontend'
                        sh 'kubectl rollout status deployment/student-app-backend'
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                sh 'npm run test:integration'
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
                        sh 'gcloud container clusters get-credentials production-cluster --zone=us-central1-a'
                        sh "kubectl set image deployment/student-app-frontend frontend=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${env.BUILD_NUMBER}"
                        sh "kubectl set image deployment/student-app-backend backend=${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${env.BUILD_NUMBER}"
                        sh 'kubectl rollout status deployment/student-app-frontend'
                        sh 'kubectl rollout status deployment/student-app-backend'
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            slackSend channel: '#devops', message: "✅ Build ${env.BUILD_NUMBER} deployed successfully!"
        }
        failure {
            slackSend channel: '#devops', message: "❌ Build ${env.BUILD_NUMBER} failed!"
        }
    }
}
