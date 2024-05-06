# frozen_string_literal: true

# This is a non-Rails example app!

ENV['KARAFKA_ENV'] ||= 'development'
Bundler.require(:default, ENV['KARAFKA_ENV'])

# Zeitwerk custom loader for loading the app components before the whole
# Karafka framework configuration
APP_LOADER = Zeitwerk::Loader.new

%w[
  lib
  app/consumers
].each(&APP_LOADER.method(:push_dir))

APP_LOADER.setup
APP_LOADER.eager_load

class OAuthTokenRefresher
  def on_oauthbearer_token_refresh(event)
    print "refreshing token\n"

    signer = AwsMskIamSaslSigner::MSKTokenProvider.new(region: ENV.fetch("AWS_REGION", nil))
    token = signer.generate_auth_token
    if token
      event[:bearer].oauthbearer_set_token(
        token: token.token,
        lifetime_ms: token.expiration_time_ms,
        principal_name: "kafka-cluster"
      )
    else
      event[:bearer].oauthbearer_set_token_failure(
        "Failed to generate token."
      )
    end
  end
end

# App class
class App < Karafka::App
  setup do |config|
    config.concurrency = 5
    config.max_wait_time = 1_000
    config.kafka = { 'bootstrap.servers': ENV['KAFKA_BOOTSTRAP_SERVERS'] }
    config.oauth.token_provider_listener = OAuthTokenRefresher.new
  end
end

Karafka.monitor.subscribe(Karafka::Instrumentation::LoggerListener.new)
Karafka.monitor.subscribe(Karafka::Instrumentation::ProctitleListener.new)
Karafka.producer.monitor.subscribe(
  WaterDrop::Instrumentation::LoggerListener.new(
    Karafka.logger,
    # If you set this to true, logs will contain each message details
    # Please note, that this can be extensive
    log_messages: false
  )
)

App.consumer_groups.draw do
  consumer_group :batched_group do
    topic :xml_data do
      config(partitions: 2)
      consumer XmlMessagesConsumer
      deserializer XmlDeserializer.new
    end

    topic :counters do
      config(partitions: 1)
      consumer CountersConsumer
    end

    topic :ping do
      # 1 day in ms
      config(partitions: 5, 'retention.ms': 86_400_000)
      consumer Pong::PingConsumer
    end

    topic :pong do
      # 1 day in ms
      config(partitions: 5, 'retention.ms': 86_400_000)
      consumer Pong::PongConsumer
    end
  end
end
