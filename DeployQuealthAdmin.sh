#!/bin/bash

#Define variables
#Git Repos
dev_repo='/Repo1/nextgen2dev/'
staginglive_repo='/Repo1/nextgen2/'
#DB Connection Strings
dbconnectionstring_dev='db: "mongodb://admin-user:admin@lon-mongos1.objectrocket.com:23135/mean-dev?authMechanism=SCRAM-SHA-1&authSource=mean-dev",'
dbconnectionstring_local='db: "mongodb://localhost/mean-dev",'
dbconnectionstring_staging='db: "mongodb://admin-user:admin@lon-mongos1.objectrocket.com:23135/mean-staging?authMechanism=SCRAM-SHA-1&authSource=mean-staging",'
dbconnectionstring_live='db: "mongodb://admin:admin@lon-mongos1.objectrocket.com:23047/mean-live?authMechanism=SCRAM-SHA-1&authSource=mean-live",'
#Ports
port_dev=3000
port_staging=4000
port_live=5000
#ng-server
ng_server='192.168.200.9'

#initial error handling
if [ -z $1 ]; then
  echo You missed an Env. Try -> ./QuealthAdmin.sh dev/staging/live
fi

if [ $1 != dev ] || [ $1 != staging ] || [ $1 != live ]; then
  echo incorrect syntax used, try: dev/staging/live
fi

#Change directory to correct repository
echo $1 Deployment selected - Quealth Admin Backend
if [ $1 = dev ]; then
  cd $dev_repo
elif [ $1 = staging ] || [ $1 = live ]; then
  cd $staginglive_repo
fi

#pull latest environment branch
if [ $1 = dev ]; then
  git pull origin $1
elif [ $1 = staging ]; then
  git pull origin $1
elif [ $1 = live ; then
  git pull origin master
fi

#copy contents from latest repo to application code folder
if [ $1 = dev ]; then
  yes | cp -rf $dev_repo* /code/$1/nextgen2
elif [ $1 = staging ] || [ $1 = live ]; then
  yes | cp -rf $staginglive_repo /code/$1/
fi

#check that the correct port is used in all.js, if not set it
if [ $1 = dev ]; then
  if [ grep -q 'port: process.env.PORT || '$port_dev',' "/code/$1/nextgen2/config/env/all.js" ]
  then
      echo Port $port_dev present
  else
      echo Port $port_dev is absent
      sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || '$port_dev', //&' code/$1/nextgen2/config/env/all.js
  fi
elif [ $1 = staging ]; then
  if [ grep -q 'port: process.env.PORT || '$port_staging',' "/code/$1/nextgen2/config/env/all.js" ]
  then
      echo Port $port_staging present
  else
      echo Port $port_staging is absent
      sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || '$port_staging', //&' code/$1/nextgen2/config/env/all.js
  fi
elif [ $1 = live ]; then
  if [ grep -q 'port: process.env.PORT || '$port_live',' "/code/$1/nextgen2/config/env/all.js" ]
  then
      echo Port $port_live present
  else
      echo Port $port_live is absent
      sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || '$port_live', //&' code/$1/nextgen2/config/env/all.js
  fi
fi

#remove redundant db connection strings (dependant on the env)
if [ $1 = dev ]; then
  sed -i'.bak' -e "s|//$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_staging||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_live||" code/$1/nextgen2/config/env/development.js
elif [ $1 = staging ]; then
  sed -i'.bak' -e "s|//$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_dev||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_live||" code/$1/nextgen2/config/env/development.js
elif [ $1 = live ]; then
  sed -i'.bak' -e "s|//$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_dev||" code/$1/nextgen2/config/env/development.js
  sed -i'.bak' -e "s|//$dbconnectionstring_staging||" code/$1/nextgen2/config/env/development.js
fi

#change the permissions of the uploads folder
chmod -R 0776 /code/$1/nextgen2/public/uploads

#copy the staging files (images) to the dev folder
if [ $1 = dev ]; then
  yes | cp -Rf /code/staging/nextgen2/public/uploads /code/$1/nextgen2/public/
elif [ $1 = staging ]; then
  yes | cp -Rf /code/dev/nextgen2/public/img /code/$1/nextgen2/public/
  yes | cp - Rf /code/dev/nextgen2/public/uploads /code/$1/nextgen2/public/
elif [ $1 = live ]; then
  ssh ningham@$ng_server
  scp -rp ningham@$ng_server:/code/staging/nextgen2/public/img /code/$1/nextgen2/public/
  scp -rp ningham@$ng_server:/code/staging/nextgen2/public/uploads /code/$1/nextgen2/public/
fi

#Remove the node_modules directory to avoid dependency conflicts
cd code/$1/nextgen2/
rm -rf node_modules

#npm install the project
npm install

#restart the forever services
forever restartall
