// Jenkinsfile
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-dockerhub-username'
        APP_NAME = 'your-app-name'
        // These will be set in Jenkins credentials
        TEST_SERVER = credentials('TEST_SERVER_IP')
        PROD_SERVER = credentials('PROD_SERVER_IP')
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'python -m pip install --upgrade pip'
                sh 'pip install -r requirements.txt'
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh 'python -m pytest tests/ --junitxml=test-results.xml'
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}")
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('', 'dockerhub-credentials') {
                        docker.image("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}").push()
                    }
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                sshagent(['docker-test-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${TEST_SERVER} \
                        "docker pull ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID} && \
                         docker stop ${APP_NAME}-test || true && \
                         docker rm ${APP_NAME}-test || true && \
                         docker run -d --name ${APP_NAME}-test -p 5000:5000 ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}"
                    """
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    // Wait for app to start
                    sh 'sleep 30'
                    sh "curl -f http://${TEST_SERVER}:5000/health || exit 1"
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sshagent(['docker-prod-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${PROD_SERVER} \
                        "docker pull ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID} && \
                         docker stop ${APP_NAME}-prod || true && \
                         docker rm ${APP_NAME}-prod || true && \
                         docker run -d --name ${APP_NAME}-prod -p 80:5000 ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}"
                    """
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
            emailext (
                subject: "SUCCESS: Job ${env.JOB_NAME} - Build ${env.BUILD_NUMBER}",
                body: "The build was successful!\nCheck details: ${env.BUILD_URL}",
                to: "team@yourcompany.com"
            )
        }
        failure {
            emailext (
                subject: "FAILED: Job ${env.JOB_NAME} - Build ${env.BUILD_NUMBER}",
                body: "The build failed!\nCheck details: ${env.BUILD_URL}",
                to: "team@yourcompany.com"
            )
        }
    }
}