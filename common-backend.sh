#!/bin/bash

source ./common.sh 
CHECK_ROOT

echo "Please Enter DB Password:: "
read -s mysql_root_password

dnf module disable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Disable nodejs:18" 

dnf module enable nodejs:20 -y &>> $LOGFILE
VALIDATE $? "Enable nodejs:20"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Install nodejs:20"

id expense &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd expense &>>$LOGFILE
    VALIDATE $? "User:: expense user creation"
else
    echo -e "Expense user already created...$Y SKIPPING $N"
fi

mkdir -p /app &>> $LOGFILE 
# -p ..> parents ..> option allows the command to create parent directories as needed, not throw error if already directory already exists
VALIDATE $? "Directory:: /app creation"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOGFILE
VALIDATE $? "Downloaded Code in /tmp as backend.zip"  

cd /app &>> $LOGFILE
rm -rf /app/* &>> $LOGFILE
VALIDATE $? "change directory to /app, remove old code"

unzip /tmp/backend.zip &>> $LOGFILE
VALIDATE $?  "Unzip backend.zip"

npm install &>> $LOGFILE
VALIDATE $?  "Download dependencies"

cp /home/ec2-user/expense-project-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $?  "Copied backend.service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $?  "Daemon Reload"

systemctl start backend &>> $LOGFILE
VALIDATE $?  "Start Backend"

systemctl enable backend &>> $LOGFILE
VALIDATE $?  "Enable Backend"

dnf install mysql -y &>> $LOGFILE
VALIDATE $?  "Install MYSQL Client"

mysql -h db.step-into-iot.cloud -uroot -p${mysql_root_password} < /app/schema/backend.sql &>> $LOGFILE
VALIDATE $?  "Schema loaded to MSQL"

systemctl restart backend &>> $LOGFILE
VALIDATE $?  "Restarting Backend"