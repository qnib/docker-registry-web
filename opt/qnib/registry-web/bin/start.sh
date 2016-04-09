#!/usr/local/bin/dumb-init /bin/bash


source /opt/qnib/consul/etc/bash_functions.sh

wait_for_srv docker-registry

/usr/share/tomcat7/bin/catalina.sh run


