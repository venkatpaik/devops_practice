pipeline{
    agent any
    tools {
        terraform 'Terraform'
    }
    
    environment {
        AWS_ACCESS_KEY = credentials('AWS_ACCESS_KEY')
        AWS_SECRET_KEY = credentials('AWS_SECRET_KEY')
        DEV_ACCESS_KEY = credentials('DEV_ACCESS_KEY')
    }

    // parameters {
    //     string(name : )
    // }
    
    stages{
        stage("git checkout"){
            steps{
                git branch: 'main', url: 'https://github.com/venkatpaik/devops_practice'
            }
        }
        stage("terraform init"){
            steps{
                sh label: 'tinit', script: 'terraform init'
            }
        }
        stage("terraform destroy"){
            steps{
                sh label: 'tdestroy', script: 'terraform destroy --auto-approve'
            }
        }
        stage("terraform apply"){
            steps{
                sh 'echo ${DEV_ACCESS_KEY}'
                sh label: 'tapply', script: 'terraform apply --auto-approve'
            }
        }
    }
}