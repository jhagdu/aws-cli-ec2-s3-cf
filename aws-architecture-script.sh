#!/bin/bash

#Variable for AMI ID and Instance Type
ami_id='ami-0947d2ba12ee1ff75'
inst_type='t2.micro'
s3_bkt_name='its-web-bkett'
echo -e "\nAMI ID is set to $ami_id and Instance Type as $inst_type"

#Getting VPC ID and Subnet ID
echo 'Working on Default VPC and Subnets'
vpc_id=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query Vpcs[0].VpcId --output text)
subnet_id=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id --query  Subnets[0].SubnetId --output text)
echo -e '\nTo change VPC, Subnet, AMI or Instance Type, Change the Variables in the Script\n'

#Create Key Pair and Describe it
echo -e '\n\nCreating Key Pair...'
aws ec2 create-key-pair --key-name webkey --query "KeyMaterial" --output text > webkey.pem
aws ec2 describe-key-pairs

#Create Security Group and Get its ID
echo -e '\n\nCreating Security Groups and Rules...'
aws ec2 create-security-group --group-name webSG --description "Web Security Group" --vpc-id $vpc_id
sg_id=$(aws ec2 describe-security-groups --filters Name=group-name,Values=webSG --query SecurityGroups[0].GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0

#Create S3 Bucket and Add objects to it
echo -e '\n\nCreating Bucket and Adding Objects to it...'
aws s3api create-bucket --bucket $s3_bkt_name --acl public-read
aws s3api put-object --bucket $s3_bkt_name --acl public-read --key image1.jpg --body image1.png

#Create CloudFront
echo -e '\nCreating Cloud Front with S3 Origin...'
cf_domain=$(aws cloudfront create-distribution --origin-domain-name $s3_bkt_name.s3.amazonaws.com --query Distribution.DomainName --output text)
echo $cf_domain

#Run Instance
echo -e '\n\nStarting an Instance...'
inst_id=$(aws ec2 run-instances --security-group-ids $sg_id --instance-type $inst_type --image-id $ami_id --key-name webkey --subnet-id $subnet_id --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Env,Value=WebProduction}]' --user-data file://user-data.sh --query Instances[0].InstanceId --output text)
aws ec2 describe-instances --instance-ids $inst_id

echo -e '\nWaiting For Instance Running State...'
while true
do
	inst_state=$(aws ec2 describe-instances --instance-ids $inst_id --query Reservations[*].Instances[*].State.Name --output text) 
	if [ $inst_state == 'running' ]
	then
		break
	else
		continue
	fi
done

inst_az=$(aws ec2 describe-instances --instance-ids $inst_id --query Reservations[*].Instances[0].Placement.AvailabilityZone --output text)
pub_ip=$(aws ec2 describe-instances --instance-ids $inst_id --query Reservations[*].Instances[*].PublicIpAddress --output text)

#Create and Attach EBS Volume
echo -e '\n\nCreating and Attaching EBS Volume...'
vol_id=$(aws ec2 create-volume --volume-type gp2 --size 1 --availability-zone $inst_az --query VolumeId --output text)

echo -e '\nWaiting For Volume to be Available...'
while true
do
        vol_state=$(aws ec2 describe-volumes --volume-ids $vol_id --query Volumes[*].State --output text)
        if [ $vol_state == 'available' ]
        then
                break
	else
                continue
        fi
done

aws ec2 attach-volume --instance-id $inst_id --volume-id $vol_id --device 'xvdf'

#Setup WebServer in EC2 instance
echo -e "\n"
chmod 400 webkey.pem
sleep 10
ssh -o "StrictHostKeyChecking no" ec2-user@$pub_ip -i webkey.pem sudo sed -i "s/CF_URL_Here/$cf_domain/g" /home/ec2-user/webpage.html
ssh -o "StrictHostKeyChecking no" ec2-user@$pub_ip -i webkey.pem bash /home/ec2-user/setup.sh

#Open the Website
echo -e "\n\nPublic IP of Instane - $pub_ip"
start chrome $pub_ip

