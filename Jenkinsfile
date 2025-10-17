/*Jenkins file for Continuous Deployment*/
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
        script {
          withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh """
              echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $DOCKER_REGISTRY
              docker push ${DOCKER_REPO}:${DOCKER_TAG}
            """
          }
        }
      }
    }

    stage('Deploy to EKS using Helm') {
        steps {
          withCredentials([
            file(credentialsId: "${KUBE_CONFIG}", variable: 'KUBECONFIG_PATH'),
            usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            sh '''
              set -e
      
              export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
              export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
              export AWS_DEFAULT_REGION=${AWS_REGION}
      
              echo "Setting up kubeconfig ..."
              cp $KUBECONFIG_PATH ./kubeconfig
              chmod 600 ./kubeconfig
              export KUBECONFIG=./kubeconfig
      
              echo "Updating kubeconfig for EKS cluster..."
              aws eks --region ${AWS_REGION} update-kubeconfig --name filmcastpro-eks-wUCMwp4H --kubeconfig ./kubeconfig
              
              echo "Deploying Helm Chart..."
              helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
                --namespace ${EKS_NAMESPACE} \
                --create-namespace \
                --set image.repository=${DOCKER_REPO} \
                --set image.tag=${DOCKER_TAG} \
                --wait --timeout 300s || \
                (echo "Helm deployment failed, rolling back ..." && \
                 helm rollback ${HELM_RELEASE} && exit 1)
      
              echo "Verifying rollout..."
              kubectl rollout status deployment/${APP_NAME} -n ${EKS_NAMESPACE} --timeout=300s
            '''
          }
        }
    }
    
    /*stage('Deploy to EKS using Helm') {
      steps {
        script {
                 withCredentials([file(credentialsId: "${KUBE_CONFIG}", variable: 'KUBECONFIG_PATH')]) {
                 sh '''
                   echo "Setting up kubeconfig ..."
                   export KUBECONFIG=$KUBECONFIG_PATH
                   aws eks --region ${AWS_REGION} update-kubeconfig --name filmcastpro-eks-wUCMwp4H || true

                   echo "Deploying Helm Chart ..."
                   helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
                     --namespace ${EKS_NAMESPACE} \
                     --create namespace \
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
    }*/

    /*stage('Update Helm values and push to Git') {
      steps {
        script {
          sh '''
            sed -i "s|tag: .*|tag: ${DOCKER_TAG}|" ${HELM_CHART_PATH}/values.yaml
            git config --global user.email "meera22_99@yahoo.com"
            git config --global user.name "meeraparigi"
            git add ${HELM_CHART_PATH}/values.yaml
            git commit -m "Update image tag to ${DOCKER_TAG} for release ${HELM_RELEASE}"
            git push origin master
          '''
        }
      }
    }*/

    /*stage('Trigger ArgoCD Deployment') {
      steps {
        withCredentials([string(credentialsId: 'argocd-token', variable: 'ARGOCD_AUTH_TOKEN')]) {
          sh '''
            argocd login argocd-server.example.com --grpc-web --username admin --password $ARGOCD_AUTH_TOKEN --insecure
            argocd app sync ${APP_NAME} --gprc-web --timeout 600
            argocd app wait ${APP_NAME} --sync --health --timeout 600
          '''
        }
      }
    } */
    
  } 
}
