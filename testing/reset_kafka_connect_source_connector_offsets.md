# Reset Kafka Connect Source Connector Offsets
Kafka Connect in distributed mode uses Kafka itself to persist the offsets of any source connectors. If you want to reset the offset of a source connector then you can do so by very carefully modifying the data in the Kafka topic itself.

### Example
In this example I’m using the [Kafka Connect File Pulse](https://github.com/osodevops/kafka-connect-file-pulse) which deploys a basic Connect File Pulse connector to parse the Kafka Connect container log4j logs before writing them into a configured topic

#### Start Docker Environment
Set the following environment variable to execute next commands.
```
$ export GITHUB_REPO_MASTER=https://raw.githubusercontent.com/osodevops/kafka-connect-file-pulse/master/
```
1. Run Confluent Platforms with Connect File Pulse
```
$ curl -sSL $GITHUB_REPO_MASTER/docker-compose.yml -o docker-compose.yml
$ docker-compose up -d
```

2. Verify that Connect Worker is running (optional)
```
$ docker-compose logs "connect-file-pulse"
```

3. Check that Connect File Pulse plugin is correctly loaded (optional)
```
$ curl -sX GET http://localhost:8083/connector-plugins | grep FilePulseSourceConnector
```

#### Create log4j parser
Next we need to start a new connector instance to parse the Kafka Connect container log4j logs before writing them into a configured topic.
1. Start a new connector instance
```
$ curl -sSL $GITHUB_REPO_MASTER/config/connect-file-pulse-quickstart-log4j.json -o connect-file-pulse-quickstart-log4j.json
 
$ curl -sX POST http://localhost:8083/connectors \
-d @connect-file-pulse-quickstart-log4j.json \
--header "Content-Type: application/json" | jq
```

2. Check connector status
```
$ curl -X GET http://localhost:8083/connectors/connect-file-pulse-quickstart-log4j | jq
```

3. Consume output topic as normal
```console
$ docker exec -it -e KAFKA_OPTS="" connect kafka-avro-console-consumer \
--topic connect-file-pulse-quickstart-log4j \
--from-beginning \
--bootstrap-server broker:29092 \
--property schema.registry.url=http://schema-registry:8081
```

You should see output which looks something like this:
```
...
{"loglevel":{"string":"INFO"},"logdate":{"string":"2019-06-16 20:41:15,247"},"message":{"string":"[main] Scanning for plugin classes. This might take a moment ... (org.apache.kafka.connect.cli.ConnectDistributed)"}}
{"loglevel":{"string":"INFO"},"logdate":{"string":"2019-06-16 20:41:15,270"},"message":{"string":"[main] Loading plugin from: /usr/share/java/schema-registry (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)"}}
{"loglevel":{"string":"INFO"},"logdate":{"string":"2019-06-16 20:41:16,115"},"message":{"string":"[main] Registered loader: PluginClassLoader{pluginLocation=file:/usr/share/java/schema-registry/} (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)"}}
{"loglevel":{"string":"INFO"},"logdate":{"string":"2019-06-16 20:41:16,115"},"message":{"string":"[main] Added plugin 'org.apache.kafka.common.config.provider.FileConfigProvider' (org.apache.kafka.connect.runtime.isolation.DelegatingClassLoader)"}}
...
```
Stop the consumer and make a note of the number of messages consumed.

### Stop connect worker
1. You now must stop all connect workers using:
```
 docker stop connect
```
### Reset connect offsets and replay events.
1. Determine the Kafka topic being used to persist the offsets. The default is usually connect-offsets
```
$ kafkacat -b localhost:9092 -L | grep connect-offsets
topic "docker-connect-offsets" with 25 partitions:
```

2. Now shutdown all connect workers that are using this topic. If you don’t do this then funny things might happen, since connect only periodically flushes offsets to the topic, and doesn’t read them from it except at startup. With the connect worker shutdown, you can now examine the topic.
```
$ kafkacat -b localhost:9092 -t docker-connect-offsets -C -K#
["connect-file-pulse-quickstart-log4j",{"name":"kafka-connect.log"}]#{"position":190479,"rows":1784,"timestamp":1604505115060}
```
We can see here using the consumer mode (-C) and a key separator character of # that the key of the message is the connector’s name plus file
`["connect-file-pulse-quickstart-log4j",{"name":"kafka-connect.log"}]` and the value of the message is the position offset in the file `{"position":190479}`

3. Now use the -f option of kafkacat to display this even more clearly, along with a bunch of other important metadata including the partition:
```
$ kafkacat -b localhost:9092 -t docker-connect-offsets -C -f '\nKey (%K bytes): %k
  Value (%S bytes): %s
  Timestamp: %T
  Partition: %p
  Offset: %o\n'
Key (68 bytes): ["connect-file-pulse-quickstart-log4j",{"name":"kafka-connect.log"}]
  Value (57 bytes): {"position":190479,"rows":1784,"timestamp":1604505115060}
  Timestamp: 1604505119970
  Partition: 17
  Offset: 1
```
Take note of the partition number, because we’ll need that shortly.

4. The payload is going to be the key, which remains fixed, and a value. The value can either be a given offset, or it can be NULL which denotes nothing, nada, nowt—start from scratch. Here’s sending a NULL, which is known as a tombstone message. Very important is that you specify the same target partition (using -p) for the message as the one that you saw above
```
$ echo '["connect-file-pulse-quickstart-log4j",{"name":"kafka-connect.log"}]#' | \
      kafkacat -b localhost:9092 -t docker-connect-offsets -P -Z -K# -p 17
```
Now when we restart the Kafka Connect worker, we can see that the file has been re-processed (note the incrementing offset value but repeating Value payloads)

### Restart connect 
1. Now the tombstone has been written we can start the connect up again using:
```
 docker start connect
```