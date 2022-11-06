#!/bin/bash

#### installing mangodb 

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
apt-get install -y mongodb-org
echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-database hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections
echo "mongodb-mongosh hold" | dpkg --set-selections
echo "mongodb-org-mongos hold" | dpkg --set-selections
echo "mongodb-org-tools hold" | dpkg --set-selections
systemctl start mongod
systemctl enable mongod
echo '
db.createUser(
  {
    user: "myadmin",
    pwd: "1Mongomongo!!",
    roles: [ { role: "userAdminAnyDatabase",db: "admin" },{ role: "backup",db: "admin" }  ]
  }
)
' > /home/ubuntu/file_admin.js
echo '
db.createUser(
{
    user: "myreader",
    pwd: "1Mongomongo!",
    roles: [ { role: "read",db: "admin" } ]
  }
)
' > /home/ubuntu/file_reader.js
mongosh admin /home/ubuntu/file_admin.js
mongosh admin /home/ubuntu/file_reader.js
sh -c 'echo "security:\n  authorization : enabled" >> /etc/mongod.conf'
sed -i "s,\\(^[[:blank:]]*bindIp:\\) .*,\\1 0.0.0.0," /etc/mongod.conf
systemctl restart mongod

#### dumping backup

#creating backupcron bash file that takes backup and uploade to storage backet

echo 'DATE=`date +%Y-%d%b-%Hh%Mm`
/bin/mongodump -u myadmin -p 1Mongomongo!
mv dump /mongodump-$DATE
tar cf  /mongodump-$DATE.tar /mongodump-$DATE
/snap/bin/gsutil cp /mongodump-$DATE.tar gs://abde-storage-bucket
rm -rf mongodump*' > /backupcron.bash

chmod 755 *

# adding entry to cronjob
echo '*/2 * * * * /bin/bash /backupcron.bash' > /mycron
/bin/crontab /mycron





