#!/bin/bash

# Set up script variables
PID_FILE=/var/run/tomcat7.pid
HTTP_URL=http://xcelgeo.cloudapp.net:8080/geoserver/openlayers/img/west-mini.png
#HTTP_URL=http://xcelgeouat.cloudapp.net:8080/geoserver/openlayers/img/west-mini.png
CATALINA_SCRIPT=/etc/init.d/tomcat7
GeoServer_LOG=/var/lib/tomcat7/webapps/geoserver/data/logs/geoserver.log
CATALINA_LOG=/var/lib/tomcat7/logs/catalina.out
LOG_COPY=/home/xcelgeo
PID=`cat $PID_FILE`
CURDATE=$(date)

# Function to kill and restart application server
function catalinarestart() {
  $CATALINA_SCRIPT stop
  sleep 5
  kill 9 $PID
  cp $GeoServer_LOG $LOG_COPY
  cp $CATALINA_LOG $LOG_COPY
  $CATALINA_SCRIPT start
}

echo Running geowatchdog on $CURDATE >> /home/xcelgeo/watchdog/watchdog.log

if [ -d /proc/$PID ]
then
  # App server is running - kill and restart it if there is no response.
  wget $HTTP_URL -T 1 --timeout=20 -O /dev/null &> /dev/null
  if [ $? -ne "0" ]
  then
  echo Restarting Catalina because $HTTP_URL does not respond, pid $PID >> /home/xcelgeo/watchdog/watchdog.log
  catalinarestart
  # else
  # echo No Problems!
  fi
else
  # App server process is not running - restart it
  echo Restarting Catalina because pid $PID is dead. >> /home/xcelgeo/watchdog/watchdog.log
  catalinarestart
fi
