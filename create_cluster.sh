YOUR_CLUSTER_NAME=$1
CONSOLE_USER_NAME=$2

if [ -z "$YOUR_CLUSTER_NAME" ] ; then
	echo "supply cluster name"
	exit
fi
if [ -z "$CONSOLE_USER_NAME" ] ; then
	echo "supply the console username that you are using so that you can use https://{$AWS_REGION}.console.aws.amazon.com/eks/home"
	exit
fi

if [ -z "${AWS_REGION}" -o -z "${ACCOUNT_ID}" ] ; then
	echo "set AWS_REGION [$AWS_REGION] and ACCOUNT_ID [$ACCOUNT_ID]"
	exit
fi

sed -i -e "s/^  name: .*/  name: $YOUR_CLUSTER_NAME/" -e "s/region: .*/region: $AWS_REGION/" cluster.yaml

VPCID=$(aws ec2 describe-vpcs --filters "Name=tag:EKSDEMO,Values=*"  --query 'Vpcs[*].{VpcId:VpcId}'  | grep -o "vpc-[a-z|0-9]*")
echo $VPCID

echo "Check if VPC etc already in cluster.yaml"
grep "vpc:" cluster.yaml
if [ $? -ne 0 ] ; then
	PRIVCATE01=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=tag:aws:cloudformation:logical-id,Values=PrivateSubnet01" --query 'Subnets[*].SubnetId'|tr -d '\n' | sed -e 's/[ |"|\[|[]//g'  -e 's/]//')
	echo $PRIVCATE01
	PRIVCATE02=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=tag:aws:cloudformation:logical-id,Values=PrivateSubnet02" --query 'Subnets[*].SubnetId'| tr -d '\n' | sed -e 's/[ |"|\[|[]//g'  -e 's/]//')
	echo $PRIVCATE02
	PUBLIC01=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=tag:aws:cloudformation:logical-id,Values=PublicSubnet01" --query 'Subnets[*].SubnetId'| tr -d '\n' | sed -e 's/[ |"|\[|[]//g'  -e 's/]//')
	echo $PUBLIC01
	PUBLIC02=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCID" "Name=tag:aws:cloudformation:logical-id,Values=PublicSubnet02" --query 'Subnets[*].SubnetId'| tr -d '\n' | sed -e 's/[ |"|\[|[]//g'  -e 's/]//')
	echo $PUBLIC02

	if [ -z "$VPCID" -o -z "$PRIVCATE01" -o -z "$PRIVCATE02" -o -z "$PUBLIC01" -o -z "$PUBLIC02" ] ; then
		echo "did not find VPC Subnets etc...."
		exit 1
	fi

	cp cluster.yaml cluster.yaml.orig

	cat >> cluster.yaml <<FOF
vpc:
  id: "$VPCID"
  subnets:
    private:
      ${AWS_REGION}a:
        id: "${PRIVCATE01}"
      ${AWS_REGION}b:
        id: "${PRIVCATE02}"
    public:
      ${AWS_REGION}a:
        id: "${PUBLIC01}"
      ${AWS_REGION}b:
        id: "${PUBLIC02}"
FOF
fi

aws configure set default.region ${AWS_REGION}

aws sts get-caller-identity | grep 'arn:aws:sts.*assumed-role'
if [ $? -ne 0 ] ; then
	echo "I dont want to create cluster with real user, rather assumed role"
	exit 1
fi

grep "name: $YOUR_CLUSTER_NAME" cluster.yaml
if [ $? != 0 ] ; then
	echo "Cluster supplied does not match cluster.yaml"
	exit 1
fi

echo "eksctl create cluster --name $YOUR_CLUSTER_NAME"
eksctl create cluster -f cluster.yaml

aws eks update-kubeconfig --name $YOUR_CLUSTER_NAME

echo "eksctl utils update-cluster-logging"
eksctl utils update-cluster-logging --enable-types=all  --region $AWS_REGION --cluster $YOUR_CLUSTER_NAME --approve

echo "eksctl utils associate-iam-oidc-provider"
eksctl utils associate-iam-oidc-provider \
	--region $AWS_REGION \
	--cluster $YOUR_CLUSTER_NAME \
	--approve

# sleep 5

#echo "curl iam_policy.json"
#curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json

echo "aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy"
aws iam create-policy \
	    --policy-name AWSLoadBalancerControllerIAMPolicy \
	        --policy-document file://iam_policy.json


echo "eksctl create iamserviceaccount"
eksctl create iamserviceaccount \
	--cluster ${YOUR_CLUSTER_NAME} --region ${AWS_REGION} \
	--namespace kube-system \
	--name aws-load-balancer-controller \
	--attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
	--override-existing-serviceaccounts \
	--approve


#echo "helm repo add eks https://aws.github.io/eks-charts"
#helm repo add eks https://aws.github.io/eks-charts
#
#echo "helm repo update"
#helm repo update
#
#echo "helm install aws-load-balancer-controller eks/aws-load-balancer-controller"
#
#helm install aws-load-balancer-controller eks/aws-load-balancer-controller  \
#-n kube-system \
#--set clusterName=$YOUR_CLUSTER_NAME         \
#--set serviceAccount.create=false  \
#--set region=$AWS_REGION   \
#--set vpcId=$VPCID  \
#--set serviceAccount.name=aws-load-balancer-controller   
#
# sleep 5

echo "Fix console"

rolearn="arn:aws:iam::${ACCOUNT_ID}:user/${CONSOLE_USER_NAME}"
echo ${rolearn}

echo "eksctl create iamidentitymapping --cluster $1 --arn ${rolearn} --group system:masters --username admin"
eksctl create iamidentitymapping --cluster $1 --arn ${rolearn} --group system:masters --username admin

echo "kubectl describe configmap -n kube-system aws-auth"
kubectl describe configmap -n kube-system aws-auth


eksctl create fargateprofile --namespace python-web --cluster $YOUR_CLUSTER_NAME --region $AWS_REGION

exit
