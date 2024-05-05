# frozen_string_literal: true

require_relative "oauth_token_refresher"
require 'waterdrop'

module Producer

  def self.start!(kafka_config)
    @producer = WaterDrop::Producer.new do |config|
      config.deliver = true
      config.kafka = kafka_config
      # can either configure the listener or subscribe to the event
      #config.oauth.token_provider_listener = OAuthTokenRefresher.new
    end

    @producer.monitor.subscribe('oauthbearer.token_refresh') do |event|
      OAuthTokenRefresher.new.on_oauthbearer_token_refresh(event)
    end

  end

  def self.produce(**args)
    @producer.produce_sync(**args)
  end
end
