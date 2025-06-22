#!/bin/bash

USERID=$( id -u )
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER=/var/log/shellscript-logs
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
echo "creating $LOGS_FOLDER"


mkdir -p $LOGS_FOLDER # -p --> It creates parent directories as needed (e.g., if /var/log/myapp/logs doesn’t exist, it will create the full path).
echo "script started executed at : $(date)" | tee -a  $LOG_FILE 

if [ $USERID -ne 0 ]
then 
    echo -e "$R ERROR: Please run with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else    
    echo -e "$G you are running with root access $N" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then    
        echo -e "$G $2 is.... SUCCESS $N " | tee -a $LOG_FILE
    else
        echo  -e " $R  $2 is failure $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi
}

dnf module disable nodejs -y
VALIDATE $? " disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? " enabling nodejs"

dnf install nodejs -y
VALIDATE $? " installing nodejs"

id roboshop
if [ $? -eq 0]
then
    echo "roboshop user is already exists"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating system user"
fi

mkdir /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
VALIDATE $? "Downloading catalogue"


cd /app
rm -rf /app/*

unzip /tmp/catalogue.zip
VALIDATE $? "unzipping catalogue"

npm install
VALIDATE $? "downloading dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service"

systemctl daemon-reload


systemctl enable catalogue 
systemctl start catalogue

VALIDATE $? "starting catalogue"


cp mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? " copying mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "installing mongodb"

mongosh --host mongodb.sreeja.site </app/db/master-data.js
VALIDATE $? "Loading data into MongoDB"