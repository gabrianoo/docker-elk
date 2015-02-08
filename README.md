# docker-elk
Docker build file for elk (ELK Stack using Redis). You need to have https://www.docker.com/ installed and running to make this useful.

To Run
------

```
docker run -h elk -d --name elk -p 9292:9292 -p 9200:9200 -p 6379:6379 otasys/elk-redis
```

To build
--------

```
git clone https://github.com/gabrianoo/docker-elk.git
docker build -t docker-elk-custom docker-elk
```

then to run that

```
docker run -h elk -d --name docker-elk -p 9292:9292 -p 9200:9200 -p 6379:6379 docker-elk-custom
```
