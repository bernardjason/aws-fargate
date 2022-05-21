sg=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].SecurityGroups' | grep sg|tail -1 | sed -e "s/ //g" -e 's/"//g')

lbal=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn'  | grep arn | sed -e "s/ //g" -e 's/"//g')


listener=$(aws elbv2 describe-listeners --load-balancer-arn  ${lbal} --query "Listeners[*].ListenerArn" | grep arn | sed -e "s/ //g" -e 's/"//g')

echo $sg ${listener}

API="eks-http-api"

aws cloudformation create-stack --stack-name $API --template-body file://api.yaml --parameters ParameterKey=APIGWVPClinkSG,ParameterValue=$sg ParameterKey=ListenerArn,ParameterValue=$listener 

#stackid=$(jq -r '.StackId' /tmp/output.stackid) 

#aws cloudformation wait stack-create-complete --stack-name $stackid


attempt=60
status=fred
while [ $attempt -gt 0 -a $status != "ROLLBACK_FAILED" -a $status != "CREATE_COMPLETE" ] ; do
	status=$(aws cloudformation describe-stacks --stack-name $API | jq -r '.Stacks[0].StackStatus')
	echo $(date) [$status]
	let attempt=$attempt-1
	sleep 5
done

aws apigatewayv2  get-apis | jq -r '.Items[] | select(.Name == "HttpApiHelloWorldEks") .ApiEndpoint' | tee current.endpoint.txt


