YOUR_CLUSTER_NAME=$1

if [ -z "$YOUR_CLUSTER_NAME" ] ; then
        echo "supply cluster name"
        exit
fi

 cidr=$(aws ec2 describe-vpcs --filters "Name=tag:EKSDEMO,Values=*"  --query 'Vpcs[*].{CidrBlock:CidrBlock}' | jq -r ".[0].CidrBlock")


aws eks update-cluster-config \
    --region $AWS_REGION  \
    --name $1  \
    --resources-vpc-config endpointPublicAccess=false,endpointPrivateAccess=true

sg=$(aws eks describe-cluster --name eks-demo --query cluster.resourcesVpcConfig.clusterSecurityGroupId --region eu-west-2 | sed 's/"//g')

aws ec2 authorize-security-group-ingress \
    --group-id $sg \
    --protocol tcp \
    --port 443 \
    --cidr $cidr
