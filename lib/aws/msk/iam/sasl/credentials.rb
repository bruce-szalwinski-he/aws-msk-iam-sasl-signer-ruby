# frozen_string_literal: true

module Aws
  module Msk
    module Iam
      module Sasl
        module Signer
          class Credentials
            def load_default_credentials
              client = Aws::Kafka::Client.new(region: "us-east-1")
              client.config.credentials
            end
          end
        end
      end
    end
  end
end
