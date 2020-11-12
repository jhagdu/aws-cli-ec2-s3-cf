# AWS Architecture includes EC2, EBS, S3 and CF  
High Availability AWS Architecture with AWS CLI which includes EC2, EBS, S3 and CloudFront  
  
# Prerequisites   
- AWS CLI should be installed  
- AWS CLI should be configured  
  * If not then configure it using "aws configure" command  
  
# Usage  
- Download or clone this repository  
- Edit the aws-architecture-script.sh  
  * Change the value of ami_id and other variable accordingly  
  * By default this script will create architecture in your default VPC, You can also change the vpc_id and subnet_id variables in script accordingly  
- Run the script using command "bash aws-architecture-script.sh"  
  
# Note  
- This is bash script, so will not work on Windows CMD, so choose a Supported Linux Platform to run  
- This script will use default profile of AWS CLI  
