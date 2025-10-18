pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-dockerhub-username'
        APP_NAME = 'team-app'
        TEST_SERVER = 'test-server-ip'
        PROD_SERVER = 'prod-server-ip'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}")
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    docker.image("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID}").inside {
                        sh 'python -m pytest tests/ --junitxml=test-results.xml'
                    }
                }
            }
            post {
                always {
                    junit 'test-results.xml'
                }
            }
        }
        
        stage('Deploy to Test') {
            steps {
                script {
                    sshagent(['docker-test-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${TEST_SERVER} \
                            "docker pull ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID} && \
                             docker-compose -f /app/docker-compose.yml up -d"
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
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
                script {
                    sshagent(['docker-prod-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${PROD_SERVER} \
                            "docker pull ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_ID} && \
                             docker-compose -f /app/docker-compose.yml up -d"
                        """
                    }
                }
            }
        }
    }
    
    post {
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