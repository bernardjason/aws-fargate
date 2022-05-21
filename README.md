# aws

aws configure set default.region ${AWS_REGION}
aws ecr create-repository --repository-name fargate-tutorial
./create_cluster.sh eks-demo Administrator
./setup_fluent_bit.sh eks-demo
(cd hello && ./create_app.sh)
(cd world && ./create_app.sh)
./setup_loadbalancer.sh
./create_api.sh 


aws cloudformation delete-stack --stack-name eks-http-api
kubectl delete ingress,deployment,service -n python-web --all
eksctl delete cluster --name eks-demo

