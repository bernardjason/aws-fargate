if [ -z "${AWS_REGION}" -o -z "${ACCOUNT_ID}" ] ; then
	echo "set AWS_REGION [$AWS_REGION] and ACCOUNT_ID [$ACCOUNT_ID]"
	exit
fi

aws sts get-caller-identity | grep 'arn:aws:sts.*assumed-role'
if [ $? -ne 0 ] ; then
	echo "I dont want to create cluster with real user, rather assumed role"
	exit 1
fi    

groups | grep docker
if [ $? -ne 0 ] ; then
	echo "Not in docker group"
	exit 1
fi

VERSION=hello-7
sed -i "s/image: .*/image: $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com\/fargate-tutorial:$VERSION/" kubernetes/deployment.yaml
docker build -t fargate-tutorial:${VERSION} .
docker tag fargate-tutorial:${VERSION} $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fargate-tutorial:${VERSION}
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/fargate-tutorial:${VERSION}
cd kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
