# Notes on workshop

## Attach to running container and tail logs

docker exec -ti orchestration_stash_1 sh -c "tail -f /var/atlassian/application-data/stash/log/atlassian-stash.log"

## Delete all and restart

docker ps | col 1 | xargs | skip 1 | xargs docker stop
docker ps -a | col 1 | xargs | skip 1 | xargs docker rm
docker rmi orchestration_stash

## Setup Digital Ocean instance standalone

export DO_TOKEN=ab89e77ec0e30281e82251c612b1a92676f59504bfb934b2e67b22373861e627

docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-size "2gb" --digitalocean-region "ams3" atlascamp-standalone

docker-machine ls
docker-machine ssh atlascamp-standalone

curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


mkdir -p /root/orchestration/stash-data/shared
cd orchestration
vim /root/orchestration/stash-data/shared/stash-config.properties
vim /root/orchestration/docker-compose.yml
docker-compose up -d
docker exec -ti orchestration_stash_1 sh -c "tail -f /var/atlassian/application-data/stash/log/atlassian-stash.log"

export DO_IP=<read ip from docker machine result>
cd $HOME/a/orchestration
ssh root@$DO_IP "mkdir -p /root/orchestration" && rsync -avz . root@$DO_IP:/root/orchestration

ssh root@$DO_IP
  cd orchestration
  curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  source setup.sh
  atlascamp start

## Orchestration notes

### Many discovery backends

- With consul:
https://registry.hub.docker.com/u/progrium/consul/
https://docs.docker.com/swarm/discovery/

Expose proper volume for postgreSQL
docker run –name my_postgres \ -d \ -v pwd/volumes/data:/var/lib/postgresql/data \ postgres

### Demo with Flocker

- Use docker-machine to setup two DO instances
export DO_TOKEN=ab89e77ec0e30281e82251c612b1a92676f59504bfb934b2e67b22373861e627
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-size "2gb" --digitalocean-region "ams3" atlascamp-java

docker-machine ip atlascamp-java
export DO_IP=45.55.201.252

chmod 0600 ~/.docker/machine/machines/atlascamp-java/id_rsa
chmod 0600 ~/.docker/machine/machines/atlascamp-java/id_rsa.pub
ssh -i ~/.docker/machine/machines/atlascamp-java/id_rsa root@$DO_IP

ssh root@$DO_IP "mkdir -p /root/orchestration" && rsync -avz --exclude '.git' . root@$DO_IP:/root/orchestration
rsync -e"ssh -i /path/to/privateKey" -avz . root@$DO_IP

docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN atlascamp-db

## Demo with swarm reprise
- Before the demo video starts!
  export DO_TOKEN=ab89e77ec0e30281e82251c612b1a92676f59504bfb934b2e67b22373861e627

- Create unique cluster id using docker registry (can use consul, etcd, zookeeper):
eval $(docker-machine env dev)
docker run swarm create

export TOKEN=$(docker run swarm create) && echo $TOKEN
5f37ca82341c02d844ce98ceb38defa7
export TOKEN=6bb47adc83e9012d74ad9fcf7eba7b78

- Source DO key:
export DO_TOKEN=ab89e77ec0e30281e82251c612b1a92676f59504bfb934b2e67b22373861e627

- Create master/manager:
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-region "ams2" --swarm --swarm-master --swarm-discovery=token://$TOKEN atlascamp-m

- Create two nodes:
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-size "2gb" --digitalocean-region "ams3" --swarm --swarm-discovery=token://$TOKEN --engine-label instance=java atlascamp-1

docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-region "ams2" --swarm --swarm-discovery=token://$TOKEN --engine-label instance=database atlascamp-2

- Check the machines have been created:

docker-machine ls

- Connect docker-machine to the swarm:

eval $(docker-machine env --swarm atlascamp-m)
docker info


- Restart docker with some labels:
vim /etc/default/docker
Add --label use=db
restart docker
relaunch swarm agent
swarm join --addr 146.185.191.120:2376 token://44ff59861287a0fb9e56c41b5da4af74

- Now we can use the labels with some constraints:
docker run -ti -P -e constraint:use==db busybox echo test

- Run postgres on `db` instance:

docker run -e constraint:instance==database --name db -e POSTGRES_PASSWORD=somepassword -p 5432:5432 -d postgres

- Run stash on a host with 2Gb of RAM:
- Change my stash-config with the right IP address (mention that the new compose will support cross host links).

docker run -e constraint:instance==java --name stash --volume /Users/nick/a/orchestration/stash-data:/var/atlassian/application-data/stash --user=root --privileged=true -p 7990:7990 -p 7999:7999 -d atlassian/stash

check license:
docker exec -t atlascamp-1/stash sh -c "ls -al /var/atlassian/application-data/stash/shared"
