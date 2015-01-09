FROM ubuntu:14.04
MAINTAINER Ahmed Hassanien <eng.ahmedgaber@gmail.com>

WORKDIR /opt

# Prerequisites
RUN apt-get update
RUN apt-get install -y wget

# Install Java
RUN apt-get -y install openjdk-7-jre-headless

# Install Redis
RUN apt-get -y install redis-server
# Configuring Applications
## Redis configuration
RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf

## Install Elastic Search
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.deb
RUN dpkg -i elasticsearch-1.4.2.deb
## Configuring Elastic Search
### Add cluster name and Add node name
RUN sed -i 's/#cluster.name: elasticsearch/cluster.name: elasticsearch/g' /etc/elasticsearch/elasticsearch.yml
RUN sed -i 's/#node.name: "Franz Kafka"/node.name: "logstash"/g' /etc/elasticsearch/elasticsearch.yml
### Allow Kibana to connect to Elastic Search
RUN echo -e "\nhttp.cors.allow-origin: \"/.*/\"\nhttp.cors.enabled: true" | tee -a /etc/elasticsearch/elasticsearch.yml

# Install Log Stash
RUN wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb
RUN dpkg -i logstash_1.4.2-1-2c0f5a1_all.deb
## Configuring Log Stash
### Shipper configuration
ADD ./logstash/logstash-shipper.conf /etc/logstash/conf.d/logstash-shipper.conf
### Indexer configuration
ADD ./logstash/logstash-indexer.conf /etc/logstash/conf.d/logstash-indexer.conf

# Install Apache and Kibana and deploy Kibana to Apache2
RUN apt-get install -y apache2
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz
RUN tar xzf kibana-3.1.2.tar.gz
RUN mkdir -p /var/www/html/kibana
RUN cp -R /opt/kibana-3.1.2/* /var/www/html/kibana/

# Install Supervisor
RUN apt-get install -y supervisor
ADD ./supervisor/elasticsearch.conf /etc/supervisor/conf.d/
ADD ./supervisor/logstash.conf /etc/supervisor/conf.d/
ADD ./supervisor/apache.conf /etc/supervisor/conf.d/
ADD ./supervisor/redis.conf /etc/supervisor/conf.d/

# Exposing Redis Server Port and Apache Server Port
EXPOSE 6379
EXPOSE 80

# Start supervisor
CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf