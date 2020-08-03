#!/bin/bash
##############################################################
# Script for Apache and Tomcat
# File:/etc/rc.d/init.d/www
##############################################################
# Setup environment for script execution
#

# chkconfig: - 91 35
# description: Starts and stops the apache and tomcat daemons \
#              used to provide Neo Chen
#
# pidfile: /var/run/www/apache.pid
# pidfile: /var/run/www/tomcat.pid
# config:  /etc/apache2/apache2.conf


#APACHE_HOME=/usr/local/apache
#TOMCAT_HOME=/usr/local/tomcat
#APACHE_USER=apache
#TOMCAT_USER=tomcat

APACHE_HOME=/usr/local/apache-evaluation
TOMCAT_HOME=/usr/local/apache-tomcat-evaluation
APACHE_USER=root
TOMCAT_USER=root

OPEN_FILES=20480

# Source function library.
if [ -f /etc/init.d/functions ] ; then
  . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
  . /etc/rc.d/init.d/functions
else
  exit 0
fi

if [ ! -d /var/run/www ] ; then
  mkdir /var/run/www
fi

if [ -f /var/lock/subsys/tomcat ] ; then
	echo " "
fi

start() {
	if [ `ulimit -n` != ${OPEN_FILES} ]; then
		ulimit -n ${OPEN_FILES}
	fi
	echo -en "\\033[1;32;1m"
	echo "Starting Tomcat $TOMCAT_HOME ..."
	echo -en "\\033[0;39;1m"
	if [ -s /var/run/www/tomcat.pid ]; then
		echo "tomcat (pid `cat /var/run/www/tomcat.pid`) already running"
	else
		su - ${TOMCAT_USER} -c "$TOMCAT_HOME/bin/catalina.sh start > /dev/null"
		echo `pgrep java` > /var/run/www/tomcat.pid
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
	if [ "`pgrep java`" = "" ]&& [ "`pgrep httpd`" = "" ]; then
		start
		exit 0
    else
		echo "Usage: $0 killall (^C)"
		echo -n "Waiting: "
    fi
    while true;
	do
		sleep 1
		if [ "`pgrep java`" = "" ] && [ "`pgrep httpd`" = "" ]; then
			break
		else
			echo -n "."
			#echo -n "Enter your [y/n]: "; read ISKILL;
		fi
	done
	echo
    start
}

status() {
		ps -aux | grep -e tomcat -e apache

		echo -en "\\033[1;32;1m"
		echo ulimit open files: `ulimit -n`
		echo -en "\\033[0;39;1m"

		echo -en "\\033[1;32;1m"
		echo -en "httpd count:"
		ps axf|grep httpd|wc -l
		echo -en "\\033[0;39;1m"
}

killall() {
	if [ "`pgrep httpd`" != "" ]; then
		echo -en "\\033[1;32;1m"
		echo "kill Apache pid(`pgrep httpd`) ..."
		kill -9 `pgrep httpd`
		echo -en "\\033[0;39;1m"
	fi
	if [ "`pgrep java`" != "" ]; then
		echo -en "\\033[1;32;1m"
		echo "kill Tomcat pid(`pgrep java`) ..."
		kill -9 `pgrep java`
		echo -en "\\033[0;39;1m"
	fi
	rm -rf /var/run/www/tomcat.pid
	rm -f /var/lock/subsys/tomcat
	rm -f /var/lock/subsys/apache
}

# Determine and execute action based on command line parameter
case "$1" in
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
		killall
		;;
	*)
		echo -en "\\033[1;32;1m"
		echo "Usage: $1 {start|stop|restart|status|killall}"
		echo -en "\\033[0;39;1m"
		;;
esac
echo -en "\\033[0;39;m"
exit 0