# docker-elk
Docker build file for elk (ELK Stack using Redis). You need to have https://www.docker.com/ installed and running to make this useful.

To Run
------

```
docker run -h elk -d --name elk -p 4000:4000 -p 8889:8889 gabrianoo/elk
```

To build
--------

```
git clone https://github.com/gabrianoo/docker-elk.git
docker build -t docker-elk-custom docker-elk
```

then to run that

```
docker run -h elk -d --name docker-elk -p 80:80 -p 6379:6379 docker-elk-custom
```

TODO
----
* Run application under non-root user account for better security
* Allow changing port numbers (currently afaict application is expecting fixed numbers)
* The application numbers should be parameters
