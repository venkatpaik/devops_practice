pipeline{
    agent any
    tools {
        terraform 'Terraform'
    }
    
    environment {
        AWS_ACCESS_KEY = credentials('AWS_ACCESS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET_KEY')
    }
    
    stages{
        stage("git checkout"){
            steps{
                script{
                        git "https://github.com/venkatpaik/devops_practice.git"
                    }
            }
        }
        stage("terraform init"){
            steps{
                sh label: 'init', script: 'terraform init'
            }
        }
        stage("terraform apply"){
            steps{
                sh label: 'apply', script: 'terraform apply --auto-approve'
            }
        }
    }
}