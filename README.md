# DragonFly
## platform for IP camera streaming to the web
___
[![View Screenshots](https://dummyimage.com/200x60/007bff/ffffff.png&text=View+Screenshots)](screenshots/README.md)
___
### run in docker 
```bash
$ docker build -t dragon_fly .
$ docker network create --subnet=192.168.1.0/24 my_network # put your subnet instead of 192.168.1.0/24   
$ docker run --network my_network -p 1234:1234 -v $(pwd):/app -v /tmp:/tmp dragon_fly
# if not runned
$ docker ps -a # to find container id
$ docker start CONTAINER ID
```