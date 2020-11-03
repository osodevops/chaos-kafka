## Latency ##
Latency is measured by a round trip from producer to Broker and Broker to consumer.
**command:**
>./kafka-run-class.sh kafka.tools.EndToEndLatency {host}:{port} {topic} {#messages} {acks} {message-size}

**example:**
>./kafka-run-class.sh kafka.tools.EndToEndLatency localhost:9092 topic_name 1000 all 400

**expected result:**
```
Topic "topic_name" does not exist. Will create topic with 1 partition(s) and replication factor = 1
0	176.68392
Avg latency: 6.5960 ms

Percentiles: 50th = 6, 99th = 16, 99.9th = 176
```