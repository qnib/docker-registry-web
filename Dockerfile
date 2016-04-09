FROM qnib/u-jdk7

## https://github.com/mkuchin/docker-registry-web/blob/master/Dockerfile
ENV DEBIAN_FRONTEND=noninteractive \
    CATALINA_HOME=/usr/share/tomcat7 \
    CATALINA_BASE=/var/lib/tomcat7 \
    REG_WEB_VER=0.0.2 \
    CATALINA_OPTS=" -Djava.security.egd=file:/dev/./urandom" \
    PATH=$CATALINA_HOME/bin:$PATH \
    REGISTRY_HOST=docker-registry.service.consul \
    REGISTRY_PORT=80
#prevent apt from installing recommended packages
RUN echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/docker-no-recommends \
 && echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/docker-no-recommends

# Install java and tomcat
RUN apt-get update && apt-get install -y tomcat7 \
 && rm -rf /var/lib/tomcat7/webapps/* \
 && rm -rf /var/lib/apt/lists/*

# fix missing folders in tomcat
RUN mkdir $CATALINA_BASE/temp \
 && mkdir -p $CATALINA_HOME/common/classes \
 && mkdir -p $CATALINA_HOME/server/classes \
 && mkdir -p $CATALINA_HOME/shared/classes

## Download 
RUN apt-get update \
 && apt-get install -y wget unzip \
 && cd /opt/ \
 && wget -q https://github.com/mkuchin/docker-registry-web/archive/v${REG_WEB_VER}.zip \
 && unzip -q v${REG_WEB_VER}.zip \
 && rm -f v${REG_WEB_VER}.zip \
 && apt-get purge -y wget unzip

# Run grails wrapper to install grails and project dependencies
WORKDIR /usr/local/app
RUN cp -r /opt/docker-registry-web-${REG_WEB_VER}/grailsw \
          /opt/docker-registry-web-${REG_WEB_VER}/application.properties . \
 && cp -r /opt/docker-registry-web-${REG_WEB_VER}/wrapper . \
 && mkdir -p ./grails-app/conf/ \
 && cp -r /opt/docker-registry-web-${REG_WEB_VER}/grails-app/conf/BuildConfig.groovy ./grails-app/conf/ \
 && ./grailsw prod clean

# Building app
RUN cp -r /opt/docker-registry-web-${REG_WEB_VER}/* . \
 && ./grailsw war ROOT.war \
 && cp ROOT.war $CATALINA_BASE/webapps/ \
# clean up
 && rm -rf /usr/local/app \
 && rm -rf /root/.grails \
 && rm -rf /root/.m2 

WORKDIR $CATALINA_BASE
# Config
RUN cp /opt/docker-registry-web-${REG_WEB_VER}/tomcat/context.xml $CATALINA_BASE/conf/ \
 && rm -rf /opt/docker-registry-web-${REG_WEB_VER}/

EXPOSE  8080
