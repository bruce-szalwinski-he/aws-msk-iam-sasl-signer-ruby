# frozen_string_literal: true

module Aws::Msk::Iam::Sasl::Signer
  class Credentials
    def load_default_credentials
      client = Aws::Kafka::Client.new(region: "us-east-1")
      client.config.credentials.credentials
    end
  end
end
