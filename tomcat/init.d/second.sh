#Apache,Tomcat 运行脚本
#!/bin/bash
##############################################################
# Script for Apache and Tomcat
# File:/etc/rc.d/init.d/www
##############################################################
# Setup environment for script execution
#

# chkconfig: - 91 35
# description: Starts and stops the apache and tomcat daemons \
#              used to provide Neo Chen<openunix@163.com>
#
# pidfile: /var/run/www/apache.pid
# pidfile: /var/run/www/tomcat.pid
# config:  /etc/apache2/apache2.conf


#APACHE_HOME=/usr/local/apache
#TOMCAT_HOME=/usr/local/tomcat
#APACHE_USER=apache
#TOMCAT_USER=tomcat

APACHE_HOME=/usr/local/apache
TOMCAT_HOME=/usr/local/tomcat
APACHE_USER=root
TOMCAT_USER=root
WAIT_TIME=10
get_apache_pid(){
    APACHE_PID=`pgrep -o httpd`
    echo $APACHE_PID
}
get_tomcat_pid(){
    TOMCAT_PID=`ps axww | grep catalina.home | grep -v 'grep' | sed q | awk '{print $1}'`
    echo $TOMCAT_PID
}

#OPEN_FILS=40960

# Source function library.
#if [ -f /etc/init.d/functions ] ; then
#  . /etc/init.d/functions
#elif [ -f /etc/rc.d/init.d/functions ] ; then
#  . /etc/rc.d/init.d/functions
#else
#  exit 0
#fi

if [ ! -d /var/run/www ] ; then
  mkdir /var/run/www
fi

#if [ -f /var/lock/subsys/tomcat ] ; then
#fi

start() {
	#if [ `ulimit -n` -le  ${OPEN_FILES} ]; then
	#	ulimit -n ${OPEN_FILES}
	#fi
	echo -en "\\033[1;32;1m"
	echo "Starting Tomcat $TOMCAT_HOME ..."
	echo -en "\\033[0;39;1m"
	if [ -s /var/run/www/tomcat.pid ]; then
		echo "tomcat (pid `cat /var/run/www/tomcat.pid`) already running"
	else
		su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh start > /dev/null"
		echo `get_tomcat_pid` > /var/run/www/tomcat.pid
		touch /var/lock/subsys/tomcat
	fi
	sleep 2
	echo -en "\\033[1;32;1m"
	echo "Starting Apache $APACHE_HOME ..."
	echo -en "\\033[0;39;1m"
	su - ${APACHE_USER} -c "$APACHE_HOME/bin/apachectl start"
	touch /var/lock/subsys/apache
}

stop() {
	echo -en "\\033[1;32;1m"
	echo "Shutting down Apache $APACHE_HOME ..."
	echo -en "\\033[0;39;1m"
	su - ${APACHE_USER} -c "$APACHE_HOME/bin/apachectl stop"
	sleep 2
	echo -en "\\033[1;32;1m"
	echo "Shutting down Tomcat $TOMCAT_HOME ..."
	echo -en "\\033[0;39;1m"
	su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh stop > /dev/null"
	rm -rf /var/run/www/tomcat.pid
	rm -f /var/lock/subsys/tomcat
	rm -f /var/lock/subsys/apache
}

restart() {
    stop
    sleep 2
    if [ -z `get_tomcat_pid` ]&& [ -z `get_apache_pid` ]; then
		start
		exit 0
    else
		echo "Usage: $0 killall (^C)"
		echo -n "Waiting: "
    fi
    while true;
	do
		sleep 1
		if [ -z `get_tomcat_pid` ] && [ -z `get_apache_pid` ]; then
			break
		else
			echo -n "."
		fi
	done
	echo
    start
}

k9restart() {
    ISEXIT='false'
    stop
    for i in `seq 1 ${WAIT_TIME}`;
    do
		if [ -z `get_tomcat_pid` ] && [ -z `get_apache_pid` ]; then
	        ISEXIT='true'
	        break
		else
			sleep 1
		fi
	done

	if [ $ISEXIT == 'false' ]; then
	    while true;
		do
			if [ -z `get_tomcat_pid` ] && [ -z `get_apache_pid` ]; then
				ISEXIT='true'
	        	break
			fi

			if [ -n `get_apache_pid` ]; then
				kill -9 `pgrep httpd`
			fi
			if [ -n `get_tomcat_pid` ]; then
				kill -9 `get_tomcat_pid`
			fi
		done
		rm -rf /var/run/www/tomcat.pid
		rm -f /var/lock/subsys/tomcat
		rm -f /var/lock/subsys/apache
	fi

	echo

	if [ $ISEXIT == 'true' ]; then
		start
	fi
}

status() {
		#ps -aux | grep -e tomcat -e apache

		echo -en "\\033[1;32;1m"
		echo ulimit open files: `ulimit -n`
		echo -en "\\033[0;39;1m"

		echo -en "\\033[1;32;1m"
		echo -en "httpd count:"
		let hc=`ps axf|grep httpd|wc -l`-1
		echo $hc
		echo -en "apache count:"
		netstat -alp | grep '*:http' | wc -l
		echo -en "tomcat count:"
		netstat -alp | grep '*:webcache' | wc -l
		echo -en "dbconn count:"
		netstat -a | grep ':3433' | wc -l
		echo -en "\\033[0;39;1m"
}

kall() {
	if [ `get_apache_pid` ]; then
		echo -en "\\033[1;32;1m"
		echo "kill Apache pid(`pgrep httpd`) ..."
		kill `pgrep httpd`
		echo -en "\\033[0;39;1m"
	fi
	if [ `get_tomcat_pid` ]; then
		echo -en "\\033[1;32;1m"
		echo "kill Tomcat pid(`pgrep java`) ..."
		kill `pgrep java`
		echo -en "\\033[0;39;1m"
	fi
	rm -rf /var/run/www/tomcat.pid
	rm -f /var/lock/subsys/tomcat
	rm -f /var/lock/subsys/apache
}

reload() {
	killall -HUP httpd
}

tomcat_restart() {
    su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh stop > /dev/null"
    rm -rf /var/run/www/tomcat.pid
    rm -f /var/lock/subsys/tomcat
    sleep 2
    if [ -z `get_tomcat_pid` ]; then
        su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh start > /dev/null"
        exit 0
    else
        echo "Usage: $0 killall (^C)"
        echo -n "Waiting: "
    fi
    while true;
    do
                sleep 1
                if [ -z `get_tomcat_pid` ]; then
			echo
                        break
                else
                        echo -n "."
                        #echo -n "Enter your [y/n]: "; read ISKILL;
                fi
    done
    su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh start > /dev/null"
    echo `get_tomcat_pid` > /var/run/www/tomcat.pid
    touch /var/lock/subsys/tomcat
}


# Determine and execute action based on command line parameter
case $1 in
    apache)
	case "$2" in
	    reload)
		reload
		;;
	    *)
		su - ${APACHE_USER} -c "${APACHE_HOME}/bin/apachectl $2"
		;;
	esac
	;;
    tomcat)
	case "$2" in
            restart)
                tomcat_restart
                ;;
	    *)
		su - ${TOMCAT_USER} -c "${TOMCAT_HOME}/bin/catalina.sh $2"
		;;
	esac
	;;
    start)
	start
	;;
    stop)
	stop
	;;
    restart)
	restart
	;;
    status)
	status
	;;
    killall)
	kall
	;;
    k9restart)
	k9restart >/dev/null
	;;
    *)
	echo -en "\\033[1;32;1m"
	echo "Usage: $0 {start|stop|restart|status|killall|k9restart}"
	echo "Usage: $0 apache {start|restart|graceful|graceful-stop|stop|reload}"
	echo "Usage: $0 tomcat {debug|run|start|restart|stop|version}"
	echo -en "\\033[0;39;1m"
	;;
esac
echo -en "\\033[0;39;m"
exit 0