# DragonFly
## platform for IP camera streaming to the web
___
[![View Screenshots](https://dummyimage.com/200x60/007bff/ffffff.png&text=View+Screenshots)](screenshots/README.md)
___
### run in docker 
```bash
$ docker build -t dragon_fly .      
$ docker run -p 1234:1234 -v $(pwd):/app -v /tmp:/tmp dragon_fly
```