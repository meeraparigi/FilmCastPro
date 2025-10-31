/* Jenkins file for Continuous Deployment */

pipeline {
  agent any

  parameters {
    choice(
      name: 'DEPLOY_METHOD',
      choices: ['helm','argocd'],
      description: 'Choose the deployment method for EKS (Helm or ArgoCD)'
    )
  }

  environment {
    AWS_REGION = 'us-east-1'
    CLUSTER_NAME = 'eks-cluster-cd-deploy'
    EKS_NAMESPACE = 'staging'
    HELM_RELEASE = 'filmcastpro-app-release'
    HELM_CHART_PATH = 'helm/filmcastpro-app'
    DOCKER_REPO = 'meeraparigi/filmcastpro-app'
    DOCKER_TAG = "${env.BUILD_NUMBER}"
    ARGO_APP_NAME = "filmcastpro-app"
    DOCKER_REGISTRY = "docker.io"
    KUBE_CONFIG = "eks-kubeconfig"
    BASE_IMAGE = "meeraparigi/node18-libatomic:latest"
  }

  tools {
    nodejs "Node18"
  }

  stages {

    stage('Run Pipeline Inside Docker Agent') {
      steps {
        script {
          // Authenticate to Docker Hub first
          withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )]) {
            sh '''
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $DOCKER_REGISTRY
            '''

            // Run the full CI/CD pipeline inside your Docker image
            docker.image("${BASE_IMAGE}").inside('-u root') {

              stage('Checkout') {
                git branch: 'master', url: 'https://github.com/meeraparigi/FilmCastPro.git'
              }

              stage('Install Dependencies') {
                sh 'npm ci'
              }

              stage('Build Application') {
                sh 'npm run build'
              }

              stage('Docker Build Image') {
                script {
                  dockerImage = docker.build("${DOCKER_REPO}:${DOCKER_TAG}", ".")
                }
              }

              stage('Push Docker Image') {
                withCredentials([usernamePassword(
                  credentialsId: 'dockerhub-creds',
                  usernameVariable: 'DOCKER_USER',
                  passwordVariable: 'DOCKER_PASS'
                )]) {
                  sh """
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $DOCKER_REGISTRY
                    docker push ${DOCKER_REPO}:${DOCKER_TAG}
                  """
                }
              }

              stage('Deploy to EKS') {
                script {
                  if (params.DEPLOY_METHOD == 'helm') {
                    echo "Deploying via Helm ..."
                    deployViaHelm()
                  } else if (params.DEPLOY_METHOD == 'argocd') {
                    echo "Deploying via ArgoCD ..."
                    deployViaArgoCD()
                  } else {
                    error("Unsupported deployment method: ${params.DEPLOY_METHOD}")
                  }
                }
              }
            } // end of docker.inside
          }
        }
      }
    }
  }
}

// ========== Deployment Functions ==========

def deployViaHelm() {
  withCredentials([
    file(credentialsId: "eks-kubeconfig", variable: 'KUBECONFIG_PATH'),
    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
  ]) {
    sh '''
      set -e

      echo "Setting up AWS credentials ..."
      export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
      export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
      export AWS_DEFAULT_REGION=${AWS_REGION}

      echo "Updating kubeconfig for EKS cluster..."
      aws eks update-kubeconfig \
        --name ${CLUSTER_NAME} \
        --region ${AWS_REGION} \
        --kubeconfig ./kubeconfig

      export KUBECONFIG=./kubeconfig

      echo "Verifying AWS identity ..."
      aws sts get-caller-identity

      echo "Verifying cluster access..."
      kubectl get nodes

      echo "Deploying Helm Chart..."
      helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
        --namespace ${EKS_NAMESPACE} \
        --create-namespace \
        --set image.repository=${DOCKER_REPO} \
        --set image.tag=${DOCKER_TAG} \
        --wait --timeout 300s || \
        (echo "Helm deployment failed, rolling back ..." && \
         helm rollback ${HELM_RELEASE} && exit 1)

      echo "Checking deployment status ..."
      kubectl rollout status deployment/${HELM_RELEASE} -n ${EKS_NAMESPACE} --timeout=180s
      echo "✅ Deployment succeeded via Helm."
    '''
  }
}

def deployViaArgoCD() {
  withCredentials([
    usernamePassword(credentialsId: 'argocd-admin-creds', usernameVariable: 'ARGOCD_USERNAME', passwordVariable: 'ARGOCD_PASSWORD')
  ]) {
    sh '''
      set -e
      echo "Logging in to ArgoCD ..."
      argocd login argocd-server.example.com --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure

      echo "Syncing ArgoCD Application ..."
      argocd app sync ${ARGO_APP_NAME} --prune --timeout 300

      echo "Waiting for ArgoCD application to become healthy ..."
      argocd app wait ${ARGO_APP_NAME} --health --timeout 300

      echo "✅ Deployment succeeded via ArgoCD."
    '''
  }
}
