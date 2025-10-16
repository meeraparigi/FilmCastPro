#Jenkins file for Continuous Deployment
pipeline {
  agent any

  environment {
    APP_NAME = "filmcastpro-app"
    DOCKER_REGISTRY = "docker.io"
    DOCKER_REPO = "meeraparigi/filmcastpro-app"
    DOCKER_TAG = "${env.BUILD_NUMBER}"
    AWS_REGION = "us-east-1"
    KUBE_CONFIG = "eks-kubeconfig"
    HELM_RELEASE = "filmcastpro-app-release"
    HELM_CHART_PATH = "helm/filmcastpro-app"
    EKS_NAMESPACE = "staging"
  }

  tools {
    nodejs "Node18"  
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'master', url: 'https://github.com/meeraparigi/FilmCastPro.git'
      }  
    }

    stage('Install Dependencies') {
      steps {
            sh 'npm ci'  
      }
    }

    stage('Build Application') {
      steps {
            sh 'npm run build'  
      }
    }

    stage('Docker Build Image') {
      steps {
        script {
          dockerImage = docker.build("${DOCKER_REPO}:${DOCKER_TAG}", ".")
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsID: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: ''DOCKER_PASS)]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $DOCKER_REGISTRY
            docker push ${DOCKER_REPO}:${DOCKER_TAG}
          '''
        }
      }
    }

    stage('Deploy to EKS using Helm') {
      steps {
        script {
                 withCredentials([file(credentialsID: "${KUBE_CONFIG}", variable: 'KUBECONFIG_PATH')]) {
                 sh '''
                   echo "Setting up kubeconfig ..."
                   export KUBECONFIG=$KUBECONFIG_PATH

                   echo "Deploying Helm Chart ..."
                   helm upgrade install ${HELM_RELEASE} ${HELM_CHART_PATH} \
                     --namespace ${EKS_NAMESPACE} \
                     --set image.repository=${DOCKER_REPO} \ 
                     --set image.tag=${DOCKER_TAG} \
                     --wait --timeout 300s || \
                     (echo "Helm deployment failed, rolling back ..." && \
                      helm rollback ${HELM_RELEASE} && exit 1)

                   echo "Verifying deployment ..."
                   kubectl rollout staus deployment/${APP_NAME} -n ${EKS_NAMESPACE} --timeout=300s 
                 '''
              }
           }
        }
    }  
  } 
}
