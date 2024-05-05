# frozen_string_literal: true

require "json"
require_relative "producer"

Payload = Data.define(:device_id, :creation_timestamp, :temperature)

KAFKA_TOPIC = ENV.fetch("KAFKA_TOPIC", nil)
KAFKA_BOOTSTRAP_SERVERS = ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", nil)

kafka_config = {
  "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
  "security.protocol": "sasl_ssl",
  "sasl.mechanisms": "OAUTHBEARER",
  "client.id": "ruby-producer"
}

print "starting\n"
Producer.start!(kafka_config)
loop do
  print "producing\n"
  payload = Payload.new(
    device_id: "1234",
    creation_timestamp: Time.now.to_i,
    temperature: rand(0..100)
  )

  Producer.produce(
    topic: KAFKA_TOPIC,
    payload: payload.to_json
  )
  sleep(10)
end
