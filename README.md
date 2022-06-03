# aws fargate hello world

Example project that will create a VPC, ec2 host that is used to create a kubernetes cluster.

Cobbled together from docs, workshops and examples.

Watch a condensed cluster, api and website creation 

https://youtu.be/JO8drfZPWcg

Cost will be about a few pounds when using for a couple of hours. 

***Make sure you delete anything you don't want to keep afterwards as it will incur a cost.***

![Alt text](screenshots/arch.png?raw=true)

First create the VPC/EC2 instance using

https://github.com/bernardjason/aws-fargate/blob/main/amazon-eks-vpc-private-subnets.yaml

This can be done via AWS console cloudformation screen or cli if you've got that installed elsewhere.

Once EC2 created and ready log onto hose and do the below steps.

I've assumed you are using an IAM user with Admin access and not the root account. Below assumes user is Administrator.

Log onto the EC2 using console

<img src="https://github.com/bernardjason/aws-fargate/blob/main/screenshots/instance.png" width="512"></img>

Switch users to ec2-user
```commandline
sudo su - ec2-user
```

checkout this project
```commandline
git clone https://github.com/bernardjason/aws-fargate.git
cd aws-fargate
```

the following will create an ECR repository, then EKS cluster, Fargate profile,
2 hello world apps, private loadbalancer, http api APIGW and an S3 website
```code
aws configure set default.region ${AWS_REGION}
aws ecr create-repository --repository-name eks-fargate
./create_cluster.sh eks-demo Administrator
./setup_fluent_bit.sh eks-demo
(cd hello && ./create_app.sh)
(cd world && ./create_app.sh)
./setup_loadbalancer.sh eks-demo
./create_api.sh 
./create_website.sh <some unique s3 bucket name>
```

the create_website.sh script creates a simple S3 website to call the 2 rest api's.

to cleanup
```commandline
aws cloudformation delete-stack --stack-name eks-http-api
kubectl delete ingress,deployment,service -n python-web --all
eksctl delete cluster --name eks-demo
```

go into cloudformation from console and delete the vpc/ec2 stack

## to make cluster visible from within VPC only

See how to restrict cluster visibility.
https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html

Note as API GW has VPC link restrict K8S cluster access the APIGW and thus S3 website will still work

run the script
```
make_private.sh <cluster name>
```
this can take a few minutes to complete once shell script runs for kubectl commands to work again.

will change cluster endpoint to private ip address and make sure the security group allows access from vpc to port 443 so kubectl etc work

# other things...

https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html

https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

```commandline
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl autoscale deployment python-web-hello -n python-web --cpu-percent=50 --min=1 --max=4
kubectl autoscale deployment python-web-world -n python-web --cpu-percent=50 --min=1 --max=4
```
