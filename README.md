# Setup instructions

- Create the consul node using `docker-machine`:

```
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN --digitalocean-region "ams2" consul

eval "$(docker-machine env consul)"

docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h node1 progrium/consul -server -bootstrap
```

- Test it by *curling*:

```
curl $(docker-machine ip consul):8500/v1/catalog/nodes
[{"Node":"node1","Address":"172.17.0.2"}]
```

- Create a cluster of 3 machines now, starting with the swarm master:

```
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN \
  --digitalocean-image "debian-8-x64" \
  --digitalocean-region "ams3" --swarm --swarm-master \
  --swarm-discovery=consul://$(docker-machine ip consul):8500 \
  --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" \
  --engine-opt="cluster-advertise=eth0:2376" \
  cluster
```

- A machine with 2Gb of RAM to run [Bitbucket Server]:

```
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN \
  --digitalocean-image "debian-8-x64" \
  --digitalocean-region "ams3" \
  --digitalocean-size "2gb" \
  --swarm \
  --swarm-discovery=consul://$(docker-machine ip consul):8500 \
  --engine-label instance=java \
  --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" \
  --engine-opt="cluster-advertise=eth0:2376" \
  node1
```

A machine to host the PostgreSQL database:

```
docker-machine create -d digitalocean --digitalocean-access-token=$DO_TOKEN \
  --digitalocean-image "debian-8-x64" \
  --digitalocean-region "ams3" \
  --swarm \
  --swarm-discovery=consul://$(docker-machine ip consul):8500 \
  --engine-label instance=db \
  --engine-opt="cluster-store=consul://$(docker-machine ip consul):8500" \
  --engine-opt="cluster-advertise=eth0:2376" \
  node2
```

- Check the machines have been created:

```
docker-machine ls

NAME      ACTIVE   DRIVER         STATE     URL                         SWARM
base      -        virtualbox     Stopped                               
cluster   *        digitalocean   Running   tcp://188.166.23.145:2376   cluster (master)
consul    -        digitalocean   Running   tcp://5.101.98.134:2376     
dev       -        virtualbox     Running   tcp://192.168.99.100:2376   
node1     -        digitalocean   Running   tcp://178.62.247.112:2376   cluster
node2     -        digitalocean   Running   tcp://178.62.212.73:2376    cluster
```

- Connect docker-machine to the swarm:

```
eval $(docker-machine env --swarm cluster)
```

- Finally the only change to the normal docker-compose up is the addition of the `--x-networking` flag:

```
docker-compose --x-networking --x-network-driver=overlay up -d
```

Only file it stores in reality is a `bitbucket.properties` file with this:

``` ini
setup.displayName=Bitbucket Server
setup.baseUrl= http://localhost:7990
setup.license=<fill your license>
setup.sysadmin.username=admin
setup.sysadmin.password=admin
setup.sysadmin.displayName=<User Name>
setup.sysadmin.emailAddress=<Email Address>
jdbc.driver=org.postgresql.Driver
jdbc.url=jdbc:postgresql://orchestration_db_1:5432/postgres
jdbc.user=postgres
jdbc.password=somepassword
```
