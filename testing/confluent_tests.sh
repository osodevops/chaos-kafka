#!/bin/bash

kafka_test()
{
   ZookeeperConnect=$(cat /etc/kafka/server.properties | grep ^zookeeper.connect= | cut -d \= -f2)
   BrokersOnline=`zookeeper-shell $ZookeeperConnect ls /brokers/ids | grep "\[" | tr -s ', ' '\n' | tr -d '[]' | wc -l`
   OfflinePartitions=`kafka-topics --zookeeper $ZookeeperConnect --describe --unavailable-partitions | wc -l`
   UnderReplicatedPartitions=`kafka-topics --zookeeper $ZookeeperConnect --describe --under-replicated-partitions | wc -l`
}

zk_tests()
{
   ZookeeperConnect=$(cat /etc/kafka/server.properties | grep ^zookeeper.connect= | cut -d \= -f2)
   ZookeepersOnline=0
   ZookeepersOffline=0
   for Node in `echo $ZookeeperConnect | tr -s ',' ' '`
   do
      nc -vz `echo $Node | tr -s ':' ' '` > /dev/null 2>&1
      [[ $? -eq 0 ]] && ZookeepersOnline=$((ZookeepersOnline+1)) || ZookeepersOffline=$((ZookeepersOffline+1))
   done
}

connectorsStatus()
{
   curl -k -X GET https://$(hostname -f):8083/connectors > /tmp/connectors 2> /dev/null
   Connectors=0
   RunningConnectors=0
   NonRunningConnectors=0

   grep -i "error" /tmp/connectors > /dev/null 2>&1
   if [ $? -eq 0 ]
   then
      echo "ERROR : Errors while fetching connectors/replicators list"
      Connectors=0
   else
      for connectorName in `cat /tmp/connectors | tr -d '[' | tr -d ']' | tr -d '"' | tr -s ',' '\n' | sort`
      do
         Connectors=$((Connectors+1))
         curl -k -X GET https://$(hostname -f):8083/connectors/${connectorName}/status  > /tmp/connectorStatus 2> /dev/null

         grep '"connector":{"state":"RUNNING"' /tmp/connectorStatus > /dev/null 2>&1
         if [ $? -eq 0 ]
         then
            egrep '"state":"FAILED"|"state":"ERROR"' /tmp/connectorStatus > /dev/null 2>&1
            if [ $? -ne 0 ]
            then
               RunningConnectors=$((RunningConnectors+1))
            else
               NonRunningConnectors=$((NonRunningConnectors+1))
            fi
         fi
      done
   fi
}

if [[ -f /etc/systemd/system/kafka.service ]]
then
    kafka_test
    zk_tests
    if [[ $(/usr/bin/systemctl is-active kafka) == "active" ]]
    then
        local_kafka=1
    else
        local_kafka=0
    fi
fi

if [[ -f /etc/systemd/system/zookeeper.service ]]
then
    zk_tests
    if [[ $(/usr/bin/systemctl is-active zookeeper) == "active" ]]
    then
        local_zookeeper=1
    else
        local_zookeeper=0
    fi

fi


if [[ -f /etc/systemd/system/connect.service ]]
then
   if [[ $(/usr/bin/systemctl is-active connect) == "active" ]]
   then
       local_connect=1
       connectorsStatus
       if [ $NonRunningConnectors -eq 0 ]
       then
           ConnectorsStatus=1
       else
           ConnectorsStatus=0
       fi
   else
       local_connect=0
       ConnectorsStatus=0
   fi
fi

echo -e "BrokersOnline=$BrokersOnline\nOfflinePartitions=$OfflinePartitions\nUnderReplicatedPartitions=$UnderReplicatedPartitions\nZookeepersOnline=$ZookeepersOnline\nZookeepersOffline=$ZookeepersOffline\nRunningConnectors=$RunningConnectors\nNonRunningConnectors=$NonRunningConnectors\nlocal_kafka=$local_kafka\nlocal_zookeeper=$local_zookeeper\nlocal_connect=$local_connect\nConnectorsStatus=$ConnectorsStatus"

