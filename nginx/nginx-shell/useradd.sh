if grep -q www /etc/shadow ;then 
    echo "user: www already exists"
else 
    groupadd www
    useradd -M -g www -s /sbin/nologin www
    echo "USER: www  Added successfully "
fi