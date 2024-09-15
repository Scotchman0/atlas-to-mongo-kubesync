#Sync handler to import periodically from Atlas in prep for cutover
#FROM quay.io/mongodb/mongodb-agent-ubi:latest

FROM ubi-8:latest
RUN yum update -y

#setup mongo
COPY repo.config /etc/yum.repos.d/mongodb-org-7.0.repo
RUN chmod 744 /etc/yum/repos.d/mongodb-org-7.0.repo
RUN sudo yum install -y mongodb-org

#enable access to target dirs
RUN mkdir -p /var/lib/mongo && mkdir /var/log/mongodb && chown -R mongod /var/lib/mongo && chown -R mongod /var/log/mongodb

#Import script
RUN mkdir -p /backup/atlas && chown -R mongod /backup/
COPY atlas-import.sh /backup/atlas-import.sh

#stage script requirements
RUN mkdir -p /backup/latest-snapshot/ /backup/logs/ /backup/atlas-snapshots/


#create local user account:


#Run Script: 
RUN /opt/atlas-import.sh



#validate sync

#todo: update me after local validation is concluded
ENTRYPOINT ["tail", "-f", "/dev/null"]