#!/bin/bash

#DO_IP=146.185.131.176

function atlascamp {
  case $1 in
  env|e)
    eval $(docker-machine env ac1)
    ;;
  reset|r)
    docker ps -q | xargs docker stop
    docker ps -aq | xargs docker rm
    ;;
  install-compose|ic)
    ssh root@$DO_IP "curl -L https://github.com/docker/compose/releases/download/1.2.0/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose"
    ssh root@$DO_IP "chmod +x /usr/local/bin/docker-compose"
    ;;
  copy-demo|cd)
    cd $HOME/a/orchestration
    ssh root@$DO_IP "mkdir -p /root/orchestration" && rsync -avz --exclude '.git' . root@$DO_IP:/root/orchestration
    ;;
  start|s)
    mkdir -p /tmp/stash/shared
    cp stash-config.properties /tmp/stash/shared/stash-config.properties
    docker-compose up -d
    ;;
  tail|t)
    docker exec -ti orchestration_stash_1 sh -c "tail -f /var/atlassian/application-data/stash/log/atlassian-stash.log"
    ;;
  help|h|*)
    echo "atlascamp demo helper - (c) 2015 Atlassian"
    echo "commands available:"
    echo " Open setup.sh and read them, for now."
    ;;
  esac
}

