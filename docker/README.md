### Docker Based Kafka Failure Testing

## Scenarios

### Scenario 1 - Leader is isolated

3 Kafka brokers: kafka-1, kafka-2 and kafka-3 and one zookeeper.

Current leader is on kafka-1 then kafka-1 blocks all incoming messages from kafka-2, kafka-3 and zookeeper

### Scenario 2 - Complete network outage

4 Kafka brokers: kafka-1, kafka-2, kafka-3 and kafka-4 and 3 zookeeper.

Simulate a complete network outage between each and every component.

When the network comes back the quorum is reformed, and the cluster is healthy.

### Scenario 3 - Broker connection loss

Network setup:
* DC-A: ZK-1, Kafka-1
* DC-B: ZK-2, Kafka-2
* DC-C: ZK-3, Kafka-3

We simulate the following connectivity loss:
* Kafka-1 --> X Kafka-3
* Kafka-2 --> X Kafka-3

All other connections are still up.
All partitions where Kafka-3 is the leader are unavailable.
If we stop Kafka-3, they are still unavailable as unclean leader election is not enabled and Kafka-3 is the only broker in ISR.