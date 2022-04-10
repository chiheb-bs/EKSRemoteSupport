# EKSRemoteSupport
Provide secure access to aws eks based on bastion and using specific provided role

# Use 

1- Specify the role to be used 

prod/terraform.tfvars :

assume_role_arn = "arn:aws:iam::11122223333:user/designated_user"

2- Update prod/main-eks.tf with the node group details you want to use.

Exp 
  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

Will create two managed groups blue and green.
blue node group will use eks_managed_node_group_defaults  default settings.
gree node group will use its proper settings.

3- Go to prod/stage folder and issue :

terraform init
terraform plan
terraform apply

# How it Works

1- Remote users updates their public keys in AWS IAM console

2- ssh to Bastion is passwordless

3- Bastion fetchs user details : public key and iam user and creates a container to hold the ssh session.

4- In bastion,  sshd_worker container fetchs  AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN and create kubeconfig file accordingly.

Here after what it does :
ssh_populate_assume_role.tpl

#!/bin/bash

KST=(`aws sts assume-role --role-arn "${assume_role_arn}" --role-session-name $(hostname) --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text`)

export AWS_ACCESS_KEY_ID=$${KST[0]}; 

export AWS_SECRET_ACCESS_KEY=$${KST[1]};

export AWS_SESSION_TOKEN=$${KST[2]}

aws eks update-kubeconfig --region region-code --name cluster-nom

5- In ordrer to enable IAM role access to EKS cluster aws_auth configmap have to be updated also with the provided role :

https://github.com/chiheb-bs/EKSRemoteSupport/blob/d1a7ab43bd039a372f73ac4272d1eafef85b495d/prod/main-eks.tf

  aws_auth_configmap_yaml = <<-EOT
  ${chomp(module.eks.aws_auth_configmap_yaml)}
  
      - rolearn: ${module.eks_managed_node_group.iam_role_arn}
      
        username: system:node:{{EC2PrivateDNSName}}
        
        groups:
        
          - system:bootstrappers
          
          - system:nodes
          
      - rolearn: ${module.self_managed_node_group.iam_role_arn}
      
        username: system:node:{{EC2PrivateDNSName}}
        
        groups:
        
          - system:bootstrappers
          
          - system:nodes
          
      - rolearn: ${module.fargate_profile.fargate_profile_arn}
      
        username: system:node:{{SessionName}}
        
        groups:
        
          - system:bootstrappers
          
          - system:nodes
          
          - system:node-proxier
          
      - rolearn: ${module.ssh-bastion-service.assume_role_arn}
      
        username: system:node:{{EC2PrivateDNSName}}
        
        groups:
        
          - system:bootstrappers
          
          - system:nodes
          
  EOT





