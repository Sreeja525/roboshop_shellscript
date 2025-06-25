#!/bin/bash

START_TIME=$(date +%s)
USERID=$( id -u )
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER=/var/log/shellscript-logs
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
echo "creating $LOGS_FOLDER"


mkdir -p $LOGS_FOLDER # -p --> It creates parent directories as needed (e.g., if /var/log/myapp/logs doesn’t exist, it will create the full path).
echo "script started executed at : $(date)" | tee -a 

if [ $USERID -ne 0 ]
then 
    echo -e "$R ERROR: Please run with root access $N" 
    exit 1 #give other than 0 upto 127
else    
    echo -e "$G you are running with root access $N"
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then    
        echo -e "$G $2 is.... SUCCESS $N " 
    else
        echo  -e " $R  $2 is failure $N" 
        exit 1 #give other than 0 upto 127
    fi
}
echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

dnf install maven -y
VALIDATE $? "installing maven"

id roboshop
if [ $? -eq 0 ]
then
    echo "roboshop user is already exists"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating system user"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  

VALIDATE $? "Downloading shipping"

rm -rf /app/* 
cd /app 
pwd
unzip /tmp/shipping.zip 
VALIDATE $? "unzipping shipping"
pwd
mvn clean package 
VALIDATE $? "Packaging the shipping application"
pwd
mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Moving and renaming Jar file"
pwd
cp $SCRIPT_DIR/shippingg.service /etc/systemd/system/shipping.service 

systemctl daemon-reload 
VALIDATE $? "Daemon Realod"

systemctl enable shipping  
VALIDATE $? "Enabling shipping"

systemctl start shipping 
VALIDATE $? "Starting shipping"

dnf install mysql -y 
VALIDATE $? "Install MySQL"

#echo "Please enter root password to setup"
#read -s MYSQL_ROOT_PASSWORD
pwd
mysql -h mysql.sreeja.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities'
if [ $? -ne 0 ]
then
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql 
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "Restart shipping"

END_TIME= $(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a 
