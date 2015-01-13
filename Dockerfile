FROM ubuntu:14.04
MAINTAINER Ahmed Hassanien <eng.ahmedgaber@gmail.com>

WORKDIR /opt

# Prerequisites
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install --fix-missing
RUN apt-get install -y wget

# Install Java
RUN apt-get -y install openjdk-7-jre-headless

# Install Redis
RUN apt-get -y install redis-server
# Configuring Applications
## Redis configuration
RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf

# Install Elastic Search
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.deb
RUN dpkg -i elasticsearch-1.4.2.deb
## Configuring Elastic Search
### Add cluster name and Add node name
RUN sed -i 's/#cluster.name: elasticsearch/cluster.name: elasticsearch/g' /etc/elasticsearch/elasticsearch.yml
RUN sed -i 's/#node.name: "Franz Kafka"/node.name: "logstash"/g' /etc/elasticsearch/elasticsearch.yml
### Allow Kibana to connect to Elastic Search
RUN echo 'http.cors.allow-origin: "/.*/"' | tee -a /etc/elasticsearch/elasticsearch.yml
RUN echo 'http.cors.enabled: true' | tee -a /etc/elasticsearch/elasticsearch.yml
### Move elastic search configurations to the right place
RUN mkdir /usr/share/elasticsearch/config
RUN cp /etc/elasticsearch/*.yml /usr/share/elasticsearch/config

# Install Log Stash
RUN wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb
RUN dpkg -i logstash_1.4.2-1-2c0f5a1_all.deb
## Configuring Log Stash
### Indexer configuration
ADD ./logstash/logstash-indexer.conf /etc/logstash/conf.d/logstash-indexer.conf

# Install Supervisor
RUN apt-get install -y supervisor
ADD ./supervisor/elasticsearch.conf /etc/supervisor/conf.d/
ADD ./supervisor/logstash.conf /etc/supervisor/conf.d/
ADD ./supervisor/kibana.conf /etc/supervisor/conf.d/
ADD ./supervisor/redis.conf /etc/supervisor/conf.d/

# Exposing Redis Server Port, Kibana Port and SYSLOG Port
EXPOSE 6379
EXPOSE 9292 
EXPOSE 9200

# Start supervisor
CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf