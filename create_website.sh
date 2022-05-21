WEBSITE=$1

if [ -z "$WEBSITE" ] ; then
	echo "Must supply website name"
	exit 1
fi

cat > my-website-policy.json <<FOF 
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$WEBSITE/*"
        }
    ]
}
FOF

url=$(cat current.endpoint.txt | sed 's/\//\\\//g')

sed -i -e "s/const hello_url = .*/const hello_url = '$url\/hello';/"  -e "s/const world_url = .*/const world_url = '$url\/world';/" html/index.html

aws s3 ls s3://$WEBSITE
if [ $? -ne 0 ] ; then
	aws s3api create-bucket --bucket $WEBSITE --region $AWS_REGION  --create-bucket-configuration LocationConstraint=$AWS_REGION
  	aws s3api put-bucket-policy --bucket $WEBSITE --policy file://my-website-policy.json  
fi
  
aws s3 ls s3://$WEBSITE
if [ $? -eq 0 ] ; then
	aws s3 sync html/ s3://$WEBSITE/   && aws s3 website s3://$WEBSITE/ --index-document index.html --error-document error.html
fi


echo "goto url  https://${WEBSITE}.s3.${AWS_REGION}.amazonaws.com/index.html"
