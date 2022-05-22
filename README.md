# aws fargate hello world

Example project that will create a VPC, ec2 host that is used to create an kubernetes cluster.

Cobbled together from docs, workshops and examples.

Watch a condensed cluster, api and website creation 

https://youtu.be/JO8drfZPWcg

Cost will be about a few pounds when uusing for a couple of hours.

(architecture diagram to follow....)

First of all create the VPC/EC2 instance using

https://github.com/bernardjason/aws-fargate/blob/main/amazon-eks-vpc-private-subnets.yaml

This can be done via AWS console cloudformation screen or cli if you've got that installed elsewhere.

Once EC2 created and ready log onto hose and do the below steps.

I've assumed you are using a user with Admin access and not the root account. Below assumes user is called Administrator.

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
```

sometimes the loadbalancer isn't ready causing create_api.sh step to fail. Go into cloudformation on console and delete and try again.

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

Note as API GW as VPC link restrict to private the API and thus S3 website will still work


