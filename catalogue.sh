#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.daws86s.blog 
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE 
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disabling nodejs"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enabling nodejs:20"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "installing nodejs"

    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating system user"

    mkdir /app curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
    CATALOGUE $? "creating catalogue application"

    cd /app 
    VALIDATE $? "changing to app directory"

    unzip /tmp/catalogue.zip
    VALIDATE $? "unzip catalogue"

    npm install &>>$LOG_FILE
    VALIDATE $? "install dependence"
  

    cp catalogue.service /etc/systemd/system/catalogue.service
    VALIDATE $? "copy systemctl service"

  
  systemctl daemon-reload catalogue

  systemctl enable catalogue
  VALIDATE $? "enabling catalogue"

  cp mongo.repo /etc/yum.repos.d/mongo.repo
  VALIDATE $? "copy mongo repo"

  dnf install mongodb-mongosh -y &>>$LOG_FILE
  VALIDATE $? "intall mongodb client"

  mongosh --host $MONGODB_HOST </app/db/master-data.js
  VALIDATE $? "load catalogue products"

  systemctl restart catalogue
  VALIDATE $? "restarted catalogue"