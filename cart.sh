#!/bin/bash

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
VALIDATE $? "Disabling default nodejs"
dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs:20"
dnf install nodejs -y
VALIDATE $? "Installing nodejs:20"

id roboshop
if [ $? -eq 0 ]
then
    echo "roboshop user is already exists"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating system user"
fi

mkdir -p /app

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Downloading cart"
cd /app 
unzip /tmp/cart.zip
VALIDATE $? "unzipping cart"

cd /app 
npm install 
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service"

systemctl daemon-reload


systemctl enable cart 
systemctl start cart
VALIDATE $? "Starting cart"