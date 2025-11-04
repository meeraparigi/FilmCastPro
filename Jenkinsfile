pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOYMENT_OPTION',
            choices: ['helm', 'argocd'],
            description: 'Select deployment method: Helm or ArgoCD'
        )
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker image tag (e.g., v1.0.0)')
    }

    environment {
        DOCKERHUB_USER   = credentials('dockerhub-username')    // Jenkins credential ID for Docker Hub username/password
        DOCKERHUB_PASS   = credentials('dockerhub-password')
        DOCKER_REPO      = "meeraparigi/filmcastpro-app"        // e.g. "mydockerhubuser/myapp"
        APP_NAME         = "filmcastpro-app"
        EKS_NAMESPACE    = "default"
        HELM_CHART_PATH  = "./helm-chart"
        KUBECONFIG       = "/var/lib/jenkins/.kube/config"
        ARGOCD_SERVER    = "argocd.example.com"                 // Update this to your ArgoCD endpoint
        ARGOCD_USER      = credentials('argocd-username')       // Jenkins credential IDs
        ARGOCD_PASS      = credentials('argocd-password')
        IMAGE_URI        = "${DOCKER_REPO}:${IMAGE_TAG}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔹 Checking out source code..."
                git branch: 'master', url: 'https://github.com/meeraparigi/FilmCastPro.git'
            }
        }

        stage('Build') {
            steps {
                echo "🔹 Building application..."
                // Example build step
                sh '''
                    # For Node.js, Python, or Java
                    npm install && npm run build
                    # mvn clean package
                    echo "Build completed"
                '''
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo "🔹 Building and pushing image to Docker Hub..."
                sh '''
                    echo "Logging into Docker Hub..."
                    echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin

                    echo "Building Docker image..."
                    docker build -t $IMAGE_URI .

                    echo "Pushing image to Docker Hub..."
                    docker push $IMAGE_URI

                    docker logout
                '''
            }
        }

        stage('Deploy to EKS') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_OPTION == 'helm' }
                    expression { params.DEPLOYMENT_OPTION == 'argocd' }
                }
            }
            steps {
                script {
                    if (params.DEPLOYMENT_OPTION == 'helm') {
                        echo "🔹 Deploying via Helm..."
                        sh '''
                            helm upgrade --install ${APP_NAME} ${HELM_CHART_PATH} \
                                --namespace ${EKS_NAMESPACE} \
                                --create-namespace \
                                --set image.repository=${DOCKER_REPO} \
                                --set image.tag=${IMAGE_TAG} \
                                --wait
                        '''
                    } else if (params.DEPLOYMENT_OPTION == 'argocd') {
                        echo "🔹 Deploying via ArgoCD..."

                        sh '''
                            echo "Logging into ArgoCD..."
                            argocd login ${ARGOCD_SERVER} \
                                --username ${ARGOCD_USER} \
                                --password ${ARGOCD_PASS} \
                                --insecure || true

                            echo "Checking if ArgoCD application ${APP_NAME} exists..."
                            if ! argocd app get ${APP_NAME} >/dev/null 2>&1; then
                                echo "⚙️  Creating ArgoCD Application ${APP_NAME}..."
                                argocd app create ${APP_NAME} \
                                    --repo https://github.com/your-org/your-repo.git \
                                    --path helm-chart \
                                    --dest-server https://kubernetes.default.svc \
                                    --dest-namespace ${EKS_NAMESPACE} \
                                    --sync-policy automated \
                                    --self-heal \
                                    --auto-prune
                            else
                                echo "✅ ArgoCD application ${APP_NAME} already exists"
                            fi

                            echo "🔄 Updating image tag in ArgoCD parameters..."
                            argocd app set ${APP_NAME} --parameter image.repository=${DOCKER_REPO}
                            argocd app set ${APP_NAME} --parameter image.tag=${IMAGE_TAG}

                            echo "🚀 Syncing ArgoCD application..."
                            argocd app sync ${APP_NAME} --async
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment via ${params.DEPLOYMENT_OPTION} succeeded."
        }
        failure {
            echo "❌ Deployment failed. Check logs above."
        }
    }
}
