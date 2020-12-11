#!/bin/bash
sudo yum update -y
sudo yum -y install httpd
sudo service httpd start  
sudo chkconfig httpd on
sudo groupadd apache
sudo usermod -a -G www ec2-user
groups
sudo chgrp -R apache /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} +
find /var/www -type f -exec sudo chmod 0664 {} +                
cd /var/www/html
echo "<h1>INST 2</h1>" > index.html