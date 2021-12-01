#!/bin/bash
#Karthickeyan Kannan - PGC Devops - Assignment Task 1 
#Automation script v0.1

# UPDATED SCRIPT FROM DEV BRANCH 
#INITIALIZE VARIABLES
myname="karthickeyan"
s3_bucket="s3://upgrad-karthickeyan/"

#UPDATE THE PACKAGE

sudo apt update -y

#CHECK IF APACHE INSTALLED, ELSE INSTALL IT
dpkg -s apache2  &> /dev/null

if [ $? -eq 0 ]; then
    echo "apache2 is installed!"
else
    echo "apache is NOT installed!"
    sudo apt install apache2
fi

#ENSURE APACHE SERVICE IS RUNNING

servstat=$(service apache2 status)

if [[ $servstat == *"active (running)"* ]]; then
  	echo "Apache process is running"
else 
	echo "Apache process is not running. Starting it..."
	sudo systemctl start apache2
	
fi

#ENSURE APACHE SERVICE IS ENABLED AT BOOT, IF NOT ENABLE IT

isenabled=$(systemctl is-enabled apache2)
if [[ $isenabled == "enabled" ]]; then
	echo "Apache service is enabled at boot"
else
	echo "Apache service is disabled. Enabling it..."
	sudo systemctl enable apache2
fi


#MAKE TAR FILE WITH ONLY .LOG FILE FROM THE /var/log/apache2/

iimestamp=$(date '+%d%m%Y-%H%M%S')
tar_filename="/tmp/"${myname}"-httpd-logs-"${timestamp}".tar"
echo $tar_filename
tar -cvf $tar_filename --absolute-names /var/log/apache2/*.log

aws s3 cp $tar_filename $s3_bucket

# AUTOMATION - V0.2
# BOOKKEEPING - INVENTORY.HTML

FILE="/var/www/html/inventory.html"
FILESIZE=$(wc -c $tar_filename | awk '{print $1}')
if test -f "$FILE"; then
    echo "$FILE exists."
    echo -e "httpd-logs\tTime\tTar\size" >> $FILE
else
    echo -e "LogType\tTimeCreated\tType\tSize" > $FILE
    echo -e "httpd-logs\t$timestamp\tTar\s$FILESIZE" >> $FILE
fi
CRONFILE="/etc/cron.d/automation"
if test -f "$CRONFILE"; then
    echo "cron file exists."
else
    echo "* * * * * root /Automation_Project/automation.sh" > $CRONFILE
fi
