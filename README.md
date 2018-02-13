# PostgreSQLSH
LSH on Postgres

# Quick start:

Install docker & docker-compose:
```
curl https://get.docker.com/ | sh
sudo pip install docker-compose
```

All commands below must be runned in current directory

For the first time launch and build image:
```
docker-compose up --build -d
```

All next launches can be runned without build:
```
docker-compose up -d
```

To connect to database environment, run:
```
docker-compose exec psdb bash
```

This directory is syncronizing with /lsh/

Possible next steps:

```
cd /lsh/lib
make install
psql -U postgres

create extension lsh;
select lsh();
```

After working with postgres, shutdown container:
```
docker-compose stop
```
