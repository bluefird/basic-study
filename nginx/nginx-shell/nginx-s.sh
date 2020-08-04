#!/bin/bash
#######################
#biuld nginx
#date 2020-08-04
#author bird
######### value #########
VERSION='nginx-1.18.0'
SDATA=/opt/source/nginx
OLDPID=`cat /usr/local/${VERSION}/logs/nginx.pid`
if [ -d "${SDATA}" ];then 
    :
else 
    mkdir -p ${SDATA}
fi
PREFIX=/usr/local/${VERSION}
NGINXARGS='--user=www --group=www  --with-http_stub_status_module --with-stream  --with-pcre  --with-http_ssl_module   --with-http_v2_module --with-http_gunzip_module  --with-http_auth_request_module '

############# source ########################
cd $SDATA
if [ -e "${VERSION}.tar.gz" ];then 
    echo "NGINX packge already exists"
else
    wget http://nginx.org/download/${VERSION}.tar.gz
    wget http://nginx.org/download/${VERSION}.tar.gz.asc
    wget http://nginx.org/keys/mdounin.key
    wget http://nginx.org/keys/maxim.key
    wget http://nginx.org/keys/sb.key
    wget http://nginx.org/keys/nginx_signing.key
fi
gpg --import *.key
gpg --verify ${VERSION}.tar.gz.asc
echo "if OK please input Y: "
read value
if [ "$value" == Y ];then 
    :
else
    exit 1
fi
############# base   env   #########################
yum -y install  gcc gcc-c++ pcre-devel pcre zlib-devel zlib openssl openssl-devel

############# add user ####################
if grep -q www /etc/shadow ;then 
    echo "user: www already exists"
else 
    groupadd www
    useradd -M -g www -s /sbin/nologin www
    echo "USER: www  Added successfully "
fi

############# biulding source #########################
#stop nginx debug
rm -rf /opt/${VERSION}
tar xvf ${VERSION}.tar.gz -C  /opt/
cd /opt/${VERSION}
sed -i '/CFLAGS="$CFLAGS -g"/d' ./auto/cc/gcc
./configure --prefix=${PREFIX} ${NGINXARGS}  && make -j4

############ update nginx ##############################
mv /usr/local/${VERSION}/sbin/nginx /usr/local/${VERSION}/sbin/oldnginx
cp ./objs/nginx /usr/local/${VERSION}/sbin/nginx
if  [ ! -z "${OLDPID}" ];then 
    kill -USR2 ${OLDPID}
    kill -WINCH ${OLDPID}
else 
    :
fi
NEWPID=`cat /usr/local/${VERSION}/logs/nginx.pid`
echo "update the new please input Y: "
read NVALUE
if [ "$NVALUE" == Y ];then 
    kill -QUIT  $OLDPID
    echo "NGINX is update sucess....."
else 
    kill -QUIT  $NEWPID
    kill -HUP $OLDPID
    mv /usr/local/${VERSION}/sbin/oldnginx  /usr/local/${VERSION}/sbin/nginx 
    echo "NGINX is update faild......"
fi
ln -s -f /usr/local/${VERSION}/sbin/nginx /usr/local/sbin/nginx