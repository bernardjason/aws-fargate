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

attempts=12
while [ $attempts -gt 0 ] ; do
	kubectl get svc -n kube-system aws-load-balancer-webhook-service
	kubectl get deployments aws-load-balancer-controller -n kube-system 
	kubectl get deployments aws-load-balancer-controller -n kube-system  | grep '2/2'
	if [ $? -eq 0 ] ; then
		attempts=0
	else
		sleep 10
	fi
	let attempts=$attempts-1
done

kubectl apply -f ingress.yaml
echo "Wait for loadbalancer to be provisioned and active"

sleep 2

LBARN=""
for i in `aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text`; do 
	aws elbv2 describe-tags --resource-arns $i --query 'TagDescriptions[*].Tags' | grep EKSDEMO > /dev/null 2>&1  ; 
	if [ $? -eq 0 ] ; then
		LBARN=$i
	fi
done
if [ -z $LBARN ] ; then
	echo "Could not find loadbalancer"
	exit 1
fi
attempts=30
while [ $attempts -gt 0 ] ; do
	state=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].State' --load-balancer-arns  $LBARN --output text)
	echo "$(date) $LBARN	$state"
	echo $state | grep -i active > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
		echo "Loadbalancer is ready"
		attempts=0
	else
		sleep 5
	fi
	let attempts=$attempts-1
done
