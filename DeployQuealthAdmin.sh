#!/bin/bash

#Define environment variables
dbconnectionstring_dev='db: "mongodb://admin-user:admin@lon-mongos1.objectrocket.com:23135/mean-dev?authMechanism=SCRAM-SHA-1&authSource=mean-dev",'
dbconnectionstring_local='//db: "mongodb://localhost/mean-dev",'
dbconnectionstring_staging='//db: "mongodb://admin-user:admin@lon-mongos1.objectrocket.com:23135/mean-staging?authMechanism=SCRAM-SHA-1&authSource=mean-staging",'
dbconnectionstring_live='//db: "mongodb://admin:admin@lon-mongos1.objectrocket.com:23047/mean-live?authMechanism=SCRAM-SHA-1&authSource=mean-live",'

if [ $1 = dev ]
then
    echo Dev Deployment selected - Quealth Admin Backend
    #change directory to dev git repo
    cd /Repo1/nextgen2dev/
    #pull latest dev branch
    git pull origin dev
    #copy contents from latest dev repo to application code folder
    yes | cp -rf /Repo1/nextgen2dev/* /code/$1/nextgen2
    #Check that port 3000 is used in all.js, if not set it
    if [ grep -q 'port: process.env.PORT || 3000,' "/code/$1/nextgen2/config/env/all.js" ]
    then
        echo Port 3000 present
    else
        echo Port 3000 is absent
        sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || 3000, //&' code/$1/nextgen2/config/env/all.js
    fi
    #Remove staging and live connection strings (make permanent git change)
    sed -i'.bak' -e "s|$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_staging||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_live||" code/$1/nextgen2/config/env/development.js
    #change the permissions of the uploads folder - chmod 0776
    chmod -R 0776 /code/$1/nextgen2/public/uploads
    #Copy the staging files (images) to the dev folder
    yes | cp -Rf /code/staging/nextgen2/public/uploads /code/$1/nextgen2/public/
    #Remove the node_modules directory to avoid dependency conflicts
    cd code/$1/nextgen2/
    rm -rf node_modules
    #npm install the project
    npm install
    #restart the forever services
    forever restartall
fi

if [ $1 = staging ]
then
    echo Staging Deployment selected - Quealth Admin Backend
    #change directory to dev git repo
    cd /Repo1/nextgen2/
    #pull latest dev branch
    git pull origin staging
    #copy contents from latest dev repo to application code folder
    yes | cp -rf /Repo1/nextgen2/ /code/$1/
    #Check that port 4000 is used in all.js, if not set it
    if [ grep -q 'port: process.env.PORT || 4000,' "/code/$1/nextgen2/config/env/all.js" ]
    then
        echo Port 4000 present
    else
        echo Port 4000 is absent
        sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || 4000, //&' code/$1/nextgen2/config/env/all.js
    fi
    #Remove local, dev and live connection strings (make permanent git change)
    sed -i'.bak' -e "s|$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_dev||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_live||" code/$1/nextgen2/config/env/development.js
    #change the permissions of the uploads folder - chmod 0776
    chmod -R 0776 /code/$1/nextgen2/public/uploads
    #Copy the dev files (images) to the staging folder
    yes | cp -Rf /code/dev/nextgen2/public/img /code/$1/nextgen2/public/
    yes | cp - Rf /code/dev/nextgen2/public/uploads /code/$1/nextgen2/public/
    #Remove the node_modules directory to avoid dependency conflicts
    cd code/$1/nextgen2/
    rm -rf node_modules
    #npm install the project
    npm install
    #restart the forever services
    forever restartall
fi

if [ $1 = live ]
then
    echo Live Deployment selected - Quealth Admin Backend
    #change directory to dev git repo
    cd /Repo1/nextgen2/
    #pull latest dev branch
    git pull origin master
    #copy contents from latest dev repo to application code folder
    yes | cp -rf /Repo1/nextgen2/ /code/$1/
    #Check that port 5000 is used in all.js, if not set it
    if [ grep -q 'port: process.env.PORT || 5000,' "/code/$1/nextgen2/config/env/all.js" ]
    then
        echo Port 5000 present
    else
        echo Port 5000 is absent
        sed -i'.bak' -e 's&port: process.env.PORT || .*, &port: process.env.PORT || 5000, //&' code/$1/nextgen2/config/env/all.js
    fi
    #Remove local, dev and staging connection strings (make permanent git change)
    sed -i'.bak' -e "s|$dbconnectionstring_local||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_dev||" code/$1/nextgen2/config/env/development.js
    sed -i'.bak' -e "s|$dbconnectionstring_staging||" code/$1/nextgen2/config/env/development.js
    #change the permissions of the uploads folder - chmod 0776
    chmod -R 0776 /code/$1/nextgen2/public/uploads
    #Copy the staging files (images) to the live folder(s)
    ssh ningham@192.168.200.9
    scp -rp ningham@192.168.200.9:/code/staging/nextgen2/public/img /code/$1/nextgen2/public/
    scp -rp ningham@192.168.200.9:/code/staging/nextgen2/public/uploads /code/$1/nextgen2/public/
    #Remove the node_modules directory to avoid dependency conflicts
    cd code/$1/nextgen2/
    rm -rf node_modules
    #npm install the project
    npm install
    #restart the forever services
    forever restartall
fi
