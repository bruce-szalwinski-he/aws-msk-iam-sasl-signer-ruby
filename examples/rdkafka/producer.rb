# frozen_string_literal: true

require "rdkafka"
require_relative "oauth_token_refresher"

module Producer
  CLIENTS = {}.freeze

  def self.from_name(client_name)
    raise "Client not found: #{client_name}\n" if CLIENTS[client_name].nil?

    CLIENTS[client_name]
  end

  def self.start!(kafka_config)
    Rdkafka::Config.oauthbearer_token_refresh_callback = method(:refresh_token)
    @producer = Rdkafka::Config.new(kafka_config).producer(native_kafka_auto_start: false)
    CLIENTS[@producer.name] = @producer
    @producer.start
  end

  def self.produce(**args)
    handle = @producer.produce(**args)
    handle.wait(max_wait_timeout: 10)
  end
end
