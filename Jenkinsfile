pipeline {
    agent any

    environment {
        // Adjust for your registry
        DOCKER_REGISTRY = "docker.io"
        DOCKER_REPO = "meeraparigi/my-sample-react-app"       // Replace with your Docker hub Username and Repo name
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"

        // SonarQube config name in Jenkins
        // SONARQUBE_ENV = "MySonarQubeServer"
        SONAR_HOST_URL = 'https://sonarcloud.io'
        SONAR_TOKEN = credentials('sonarcloud-token') // store token in Jenkins credentials

        // Teams Webhook credential ID (Secret Text)
        TEAMS_WEBHOOK_ID = 'teams-webhook'
    }

    tools {
        // If you installed NodeJS plugin in Jenkins, name must match Tools config
        nodejs "Node18"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('sample-react-app') {
                    sh 'npm ci'
                }    
            }
        }      

        stage('Run Unit Test') {
            steps {
                dir('sample-react-app') {
                    sh 'npm test -- --watchAll=false'
                }
            }
        }

        stage('Build React App & Sonar Scan') {
            steps {
                dir('sample-react-app') {
                    sh 'npm run build'
                }
            }
        }   

        /* stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=my-sample-react-app \
                      -Dsonar.sources=src \
                      -Dsonar.host.url=$SONAR_HOST_URL \
                      -Dsonar.login=$SONAR_AUTH_TOKEN
                    '''
                }
            }
        } */ 

        stage('Create Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build(
                        "${DOCKER_REPO}:${DOCKER_IMAGE_TAG}",
                        "-f Dockerfile sample-react-app"
                    )
                }
            }
        }

        /* stage('Container Image Scanning - Trivy') {
            steps {
                sh """
                  trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}
                """
            }
        } */

        stage('Push Docker Image to Registry') {
            steps {
                script {
                    // DockerHub login
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                          echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $DOCKER_REGISTRY
                          docker push ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}
                        """
                    }
                }
            }
        }

        /* stage('Deploy to Kubernetes Staging') {
            steps {
                // Assuming kubeconfig is present on agent or loaded from credentials
                sh """
                  kubectl set image deployment/my-sample-react-app my-sample-react-app=${DOCKER_REPO}:${DOCKER_IMAGE_TAG} -n staging
                """
            }
        } */
    }
  
    post {
        success {
            withCredentials([string(credentialsId: "${TEAMS_WEBHOOK_ID}", variable: 'TEAMS_WEBHOOK')]) {
                sh """
                  curl -H 'Content-Type: application/json' \
                    -d '{"text":"✅ Build #${env.BUILD_NUMBER} succeeded for ${env.JOB_NAME}"}' \
                    $TEAMS_WEBHOOK
                """
            }
        }
        failure {
            withCredentials([string(credentialsId: "${TEAMS_WEBHOOK_ID}", variable: 'TEAMS_WEBHOOK')]) {
                sh """
                  curl -H 'Content-Type: application/json' \
                    -d '{"text":"❌ Build #${env.BUILD_NUMBER} failed for ${env.JOB_NAME}"}' \
                    $TEAMS_WEBHOOK
                """
            }
        }
    }
}
