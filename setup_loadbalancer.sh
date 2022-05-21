YOUR_CLUSTER_NAME=$1

if [ -z "$YOUR_CLUSTER_NAME" ] ; then
	echo "supply cluster name"
	exit
fi

if [ -z "${AWS_REGION}" -o -z "${ACCOUNT_ID}" ] ; then
	echo "set AWS_REGION [$AWS_REGION] and ACCOUNT_ID [$ACCOUNT_ID]"
	exit
fi

VPCID=$(aws ec2 describe-vpcs --filters "Name=tag:EKSDEMO,Values=*"  --query 'Vpcs[*].{VpcId:VpcId}'  | grep -o "vpc-[a-z|0-9]*")
echo $VPCID

echo "helm repo add eks https://aws.github.io/eks-charts"
helm repo add eks https://aws.github.io/eks-charts

echo "helm repo update"
helm repo update

echo "helm install aws-load-balancer-controller eks/aws-load-balancer-controller"

helm install aws-load-balancer-controller eks/aws-load-balancer-controller  \
 -n kube-system \
 --set clusterName=$YOUR_CLUSTER_NAME         \
 --set serviceAccount.create=false  \
 --set region=$AWS_REGION   \
 --set vpcId=$VPCID  \
 --set serviceAccount.name=aws-load-balancer-controller   

attempts=30
while [ $attempts -gt 0 ] ; do
	kubectl get deployments aws-load-balancer-controller -n kube-system
	kubectl get svc -n kube-system aws-load-balancer-webhook-service
	if [ $? -eq 0 ] ; then
		attempts=0
	fi
	let attempts=$attempts-1
done

kubectl apply -f ingress.yaml
