YOUR_CLUSTER_NAME=$1

if [ -z "$YOUR_CLUSTER_NAME" ] ; then
	        echo "supply cluster name"
		        exit
fi
if [ -z "${AWS_REGION}" -o -z "${ACCOUNT_ID}" ] ; then
	        echo "set AWS_REGION [$AWS_REGION] and ACCOUNT_ID [$ACCOUNT_ID]"
		        exit
fi

aws sts get-caller-identity | grep 'arn:aws:sts.*assumed-role'
if [ $? -ne 0 ] ; then
	        echo "I dont want to create cluster with real user, rather assumed role"
		        exit 1
fi

kubectl apply -f aws-observability-namespace.yaml


rolename=$(eksctl get fargateprofile --cluster ${YOUR_CLUSTER_NAME}  -o yaml --name fp-default | grep podExecutionRoleARN | sed "s!  podExecutionRoleARN: arn:aws:iam::975820831807:role/!!" )
echo $rolename

#kubectl apply -f fluentbit-config.yaml
kubectl apply -f aws-logging-cloudwatch-configmap.yaml
sleep 2

kubectl -n aws-observability get cm

aws iam list-policies --scope Local  --query 'Policies[*].{PolicyName:PolicyName}' | grep FluentBitEKSFargate
if [ $? -ne 0 ] ; then
	aws iam create-policy \
	        --policy-name FluentBitEKSFargate \
		        --policy-document file://permissions.json 
else
	echo "FluentBitEKSFargate policy already exists, wont recreate it"
fi

aws iam attach-role-policy \
	        --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/FluentBitEKSFargate \
		        --role-name $rolename
