#!/bin/bash

cat <<EOF > /home/ec2-user/webpage.html
<!DOCTYPE html>
<html>
<head>
<title>ARTH Task</title>
</head>

<body bgcolor="yellow">
<center>
<h1>My Website</h1>
<h2>ARTH Task to Deploy Website on AWS EC2 with S3 and CloudFront</h2><br>
<img src="http://CF_URL_Here/image1.png" height=500 />
<h3>Thanks Sir Vimal Daga <br>LinuxWorld Informatics Pvt. Ltd.</h3><br><br>
</center>
</body>
</html>
EOF

cat <<EOF > /home/ec2-user/setup.sh
#!/bin/bash

echo -e "\nInstalling httpd..."
sudo yum install httpd -y > /dev/null
sudo yum install parted -y > /dev/null
echo "Creating Partition and Mounting EBS Volume..."
sudo parted -a optimal /dev/xvdf mklabel gpt mkpart primary 0% 100% > /dev/null
sudo mkfs.ext4 /dev/xvdf1 > /dev/null
sudo mount /dev/xvdf1 /var/www/html/ > /dev/null
echo "Setting Up Webserver..."
sudo cp /home/ec2-user/webpage.html /var/www/html/index.html > /dev/null
sudo systemctl start httpd > /dev/null
sudo systemctl enable httpd > /dev/null
echo "All Done"
EOF

chmod +x /home/ec2-user/setup.sh
