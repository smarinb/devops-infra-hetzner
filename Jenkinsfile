pipeline {
    agent any

    environment {
        IMAGE = "ghcr.io/smarinb/devops-infra-api:latest"
        REGISTRY = "ghcr.io"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE} ./app"
            }
        }

        stage('Test') {
            steps {
                sh """
                    docker run --rm ${IMAGE} python -c "import app; print('Import OK')"
                """
            }
        }

        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'REGISTRY_USER',
                    passwordVariable: 'REGISTRY_TOKEN'
                )]) {
                    sh """
                        echo ${REGISTRY_TOKEN} | docker login ${REGISTRY} -u ${REGISTRY_USER} --password-stdin
                        docker push ${IMAGE}
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'deploy-ssh-key',
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no devops@46.225.149.114 '
                            cd ~/devops-infra-hetzner
                            git pull origin main
                            docker compose pull
                            docker compose up -d
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
