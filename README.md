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

create table tab (
col float4[]
);

insert into tab values('{0, 0.1, 0.5, 0.3}'), ('{0.2, 0.1, 0.25, 0.3}'), ('{100, 100.5, 100.2, 100}'), ('{100.1, 100.2, 100.3, 100.4}');

select create_lsh_index('tab', 'col', 1);
select * FROM lsh_nearest('{0,0,0,0}', 'tab', 'col') as f(col real[]);
select * FROM lsh_nearest('{100,100,100,100}', 'tab', 'col') as f(col real[]);
select * FROM lsh_nearest('{100, 101.2, 100.2, 100}', 'tab', 'col') as f(col real[]);
```

After working with postgres, shutdown container:
```
docker-compose stop
```
