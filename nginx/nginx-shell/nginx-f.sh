#!/bin/bash
#######################
#biuld nginx
#date 2020-08-04
#author bird
######### value #########
VERSION='nginx-1.18.0'
SDATA=/opt/source/nginx
if [ -d "${SDATA}" ];then 
    :
else 
    mkdir -p ${SDATA}
fi
PREFIX=/usr/local/${VERSION}
NGINXARGS='--user=www --group=www  --with-http_stub_status_module --with-stream  --with-pcre  --with-http_ssl_module   --with-http_v2_module --with-http_gunzip_module  --with-http_auth_request_module '

############# source ########################
cd $SDATA
if [ !-e "${VERSION}.tar.gz" ];then 
    wget http://nginx.org/download/${VERSION}.tar.gz
    wget http://nginx.org/download/${VERSION}.tar.gz.asc
    wget http://nginx.org/keys/mdounin.key
    wget http://nginx.org/keys/maxim.key
    wget http://nginx.org/keys/sb.key
    wget http://nginx.org/keys/nginx_signing.key
else
    echo "NGINX packge already exists"
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
./configure --prefix=${PREFIX} ${NGINXARGS}  && make -j4 && make install
############# system conf   #########################
if [ -d "/usr/local/${VERSION}" ];then 
        :
else
        exit 2
fi
ln -s -f /usr/local/${VERSION} /usr/local/nginx
ln -s -f /usr/local/${VERSION}/sbin/nginx /usr/local/sbin/
cat > /usr/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/sbin/nginx -t
ExecStart=/usr/local/sbin/nginx
ExecReload=/usr/local/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

################### start nginx server ####################
systemctl daemon-reload
systemctl enable nginx.service
systemctl start nginx.service

if [ $? == 0 ];then 
    :
else 
    exit 2
fi
#################### end   ########################
echo "nginx server is sucess...."