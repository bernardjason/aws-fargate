# aws

example project that will create a VPC, ec2 host that is used to create an kubernetes cluster.

Cost will be about a few pounds when uusing for a couple of hours.

```code
aws configure set default.region ${AWS_REGION}
aws ecr create-repository --repository-name fargate-tutorial
./create_cluster.sh eks-demo Administrator
./setup_fluent_bit.sh eks-demo
(cd hello && ./create_app.sh)
(cd world && ./create_app.sh)
./setup_loadbalancer.sh eks-demo
./create_api.sh 
./create_website.sh <some unique s3 bucket name>


aws cloudformation delete-stack --stack-name eks-http-api
kubectl delete ingress,deployment,service -n python-web --all
eksctl delete cluster --name eks-demo

```

