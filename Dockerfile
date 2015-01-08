FROM ubuntu:14.04
MAINTAINER Ahmed Hassanien <eng.ahmedgaber@gmail.com>

WORKDIR /opt

# Install Dependencies Redis and ELK
## Installing WGet Apache2 Redis
RUN apt-get update && apt-get install wget openjdk-7-jre-headless apache2 redis-server -y
## Installing JDK
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u25-b17/jdk-8u25-linux-x64.tar.gz
RUN tar xzf jdk-8u25-linux-x64.tar.gz
RUN update-alternatives --install "/usr/bin/java" "java" "/opt/jdk1.8.0_25/bin/java" 1
RUN update-alternatives --set java /opt/jdk1.8.0_25/bin/java
## Install Elastic Search
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.deb
RUN dpkg -i elasticsearch-1.4.2.deb
## Install Log Stash
RUN wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb
RUN dpkg -i logstash_1.4.2-1-2c0f5a1_all.deb
## Install Kibana
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz
RUN tar xzf kibana-3.1.2.tar.gz

# Configure Redis
## Backup Redis configuration
RUN cp /etc/redis/redis.conf /etc/redis/redis.conf_BKP
## Bind Redis to your public interface
RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
## Restart Redis to changes to take effect
RUN service redis-server restart

# Configure Elastic Search
## Backup Elastic Search configuration
RUN cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml_BKP
## Add cluster name and Add node name
RUN sed -i 's/#cluster.name: elasticsearch/cluster.name: elasticsearch/g' /etc/elasticsearch/elasticsearch.yml
RUN sed -i 's/#node.name: "Franz Kafka"/node.name: "logstash"/g' /etc/elasticsearch/elasticsearch.yml
## Allow Kibana to connect to Elastic Search
RUN echo -e "\nhttp.cors.allow-origin: \"/.*/\"\nhttp.cors.enabled: true" | tee -a /etc/elasticsearch/elasticsearch.yml
## To start elasticsearch by default on bootup
RUN update-rc.d elasticsearch defaults 95 10
## Restart Elastic Search to changes to take effect
RUN service elasticsearch restart

# Configure Log Stash
## Shipper configuration
RUN echo -e 'input{\n  file {\n    type => "apache-access"\n    path => "/var/log/apache2/*access.log"\n  }\n  file {\n    type => "apache-error"\n    path => "/var/log/apache2/*error.log"\n  }\n}\nfilter {\n  grok {\n    match => { "message" => "%{COMBINEDAPACHELOG}" }\n  }\n  date {\n  match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]\n  }\n}\noutput {\n  stdout { }\n  redis {\n    host => "127.0.0.1"\n    port => 6379\n    data_type => "list"\n    key => "logstash"\n  }\n}\n' | tee /etc/logstash/conf.d/logstash-shipper.conf
## Indexer configuration
RUN echo -e 'input {\n  redis {\n    host => "127.0.0.1"\n    port => 6379\n    type => "redis"\n    data_type => "list"\n    key => "logstash"\n  }\n}\noutput { stdout { }\n  elasticsearch {\n    cluster => "elasticsearch"\n  }\n}\n' | tee /etc/logstash/conf.d/logstash-indexer.conf
## Restart Log Stash to changes to take effect
RUN service logstash restart

# Configuring Kibana
## Backup Kibana configuration
RUN cp /opt/kibana-3.1.2/config.js /opt/kibana-3.1.2/config.js_BKP
## Deploy to Apache2
RUN mkdir -p /var/www/html/kibana
RUN cp -R /opt/kibana-3.1.2/* /var/www/html/kibana/

EXPOSE 6379 80
