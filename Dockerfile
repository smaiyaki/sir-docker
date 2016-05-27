# Ubuntu

FROM ubuntu:16.04
MAINTAINER Sultan Maiyaki

RUN apt-get update
RUN apt-get  install -q -y curl
#version of service desk to download
ARG SD=3.1.7
ARG JIRA=7.1.7

# install java 8
ENV DEBIAN_FRONTEND noninteractive

ENV VERSION 8
ENV UPDATE 91
ENV BUILD 14

ENV JAVA_HOME /usr/lib/jvm/java-${VERSION}-oracle

ENV OPENSSL_VERSION 1.0.2g

RUN apt-get update && apt-get install ca-certificates curl \
	gcc libc6-dev libssl-dev make \
	-y --no-install-recommends && \
	curl --silent --location --retry 3 --cacert /etc/ssl/certs/GeoTrust_Global_CA.pem \
	--header "Cookie: oraclelicense=accept-securebackup-cookie;" \
	http://download.oracle.com/otn-pub/java/jdk/"${VERSION}"u"${UPDATE}"-b"${BUILD}"/jdk-"${VERSION}"u"${UPDATE}"-linux-x64.tar.gz \
	| tar xz -C /tmp && \
	mkdir -p /usr/lib/jvm && mv /tmp/jdk1.${VERSION}.0_${UPDATE} "${JAVA_HOME}" && \
	curl --silent --location --retry 3 --cacert /etc/ssl/certs/GlobalSign_Root_CA.pem \
	https://www.openssl.org/source/openssl-1.0.2g.tar.gz \
	| tar xz -C /tmp && \
	cd /tmp/openssl-1.0.2g && \
		./config --prefix=/usr && \
		make clean && make && make install && \
	apt-get remove --purge --auto-remove -y \
		gcc \
		libc6-dev \
		libssl-dev \
		make && \
	apt-get autoclean && apt-get --purge -y autoremove && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1 && \
	update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1 && \
	update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1 && \
	update-alternatives --set java "${JAVA_HOME}/bin/java" && \
	update-alternatives --set javaws "${JAVA_HOME}/bin/javaws" && \
	update-alternatives --set javac "${JAVA_HOME}/bin/javac"

RUN curl -Lks https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-${JIRA}-jira-${JIRA}.tar.gz -o /root/jira_software.tar.gz
RUN /usr/sbin/useradd --create-home --home-dir /usr/local/jira --shell /bin/bash jira
RUN  mkdir -p /opt/jira # JIRA installation directory
RUN  tar zxf /root/jira_software.tar.gz --strip=1 -C /opt/jira
RUN  mkdir -p /opt/jira-home  # JIRA home directory
RUN mkdir -p /opt/jira-home/database
RUN  echo "jira.home = /opt/jira-home" > /opt/jira/atlassian-jira/WEB-INF/classes/jira-application.properties

# copy all the necessary files
COPY h2db.mv.db /opt/jira-home/database
COPY dbconfig.xml /opt/jira-home/
# setup and import the DB
WORKDIR /opt/jira/bin
EXPOSE 8080
RUN chmod a+x start-jira.sh
RUN rm -f /opt/jira-home/.jira-home.lock
CMD ["/opt/jira/bin/start-jira.sh", "-fg"]
