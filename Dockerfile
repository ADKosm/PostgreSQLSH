FROM postgres:latest

RUN apt-get update
RUN apt-get install make -y
RUN apt-get install postgresql-server-dev-10 -y
RUN apt-get install gcc -y

ADD preparePostgres.sh /docker-entrypoint-initdb.d/preparePostgres.sh
RUN chmod 755 /docker-entrypoint-initdb.d/preparePostgres.sh
