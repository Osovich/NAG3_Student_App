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
        
        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'docker build -t ${IMAGE_NAME}-frontend:${BUILD_NUMBER} .'
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'docker build -t ${IMAGE_NAME}-backend:${BUILD_NUMBER} .'
                }
            }
        }
        
        stage('Run Tests') {
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
                    sh 'gcloud auth configure-docker'
                    sh 'docker tag ${IMAGE_NAME}-frontend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${BUILD_NUMBER}'
                    sh 'docker tag ${IMAGE_NAME}-backend:${BUILD_NUMBER} ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${BUILD_NUMBER}'
                    sh 'docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-frontend:${BUILD_NUMBER}'
                    sh 'docker push ${DOCKER_REGISTRY}/${PROJECT_ID}/${IMAGE_NAME}-backend:${BUILD_NUMBER}'
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                sh 'kubectl apply -f k8s/test/'
                sh 'kubectl rollout status deployment/frontend-test -n test'
                sh 'kubectl rollout status deployment/backend-test -n test'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                sh 'kubectl apply -f k8s/production/'
                sh 'kubectl rollout status deployment/frontend-prod -n production'
                sh 'kubectl rollout status deployment/backend-prod -n production'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
