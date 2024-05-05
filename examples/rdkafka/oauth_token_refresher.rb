# frozen_string_literal: true

require "aws_msk_iam_sasl_signer"
require "rdkafka"

class OAuthTokenRefresher
  def refresh_token(client_name)
    print "refreshing token\n"
    client = Producer.from_name(client_name)
    signer = AwsMskIamSaslSigner::MSKTokenProvider.new(region: ENV.fetch("AWS_REGION", nil))
    token = signer.generate_auth_token

    if token
      client.oauthbearer_set_token(
        token: token.token,
        lifetime_ms: token.expiration_time_ms,
        principal_name: "kafka-cluster"
      )
    else
      client.oauthbearer_set_token_failure(
        "Failed to generate token."
      )
    end
  end
end

def refresh_token(_config, client_name)
  OAuthTokenRefresher.new.refresh_token(client_name)
end
