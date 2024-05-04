# frozen_string_literal: true

require "aws_msk_iam_sasl_signer"
require "rdkafka"

class OAuthTokenRefresher
  def refresh_token(client_name)
    print "refreshing token\n"
    signer = AwsMskIamSaslSigner::MSKTokenProvider.new(region: ENV['AWS_REGION'])
    token = signer.generate_auth_token

    client = Producer.from_name(client_name)
    client&.oauthbearer_set_token(
      token: token.token,
      lifetime_ms: token.expiration_time_ms,
      principal_name: 'kafka-cluster'
    )
  end
end

def refresh_token(_config, client_name)
  OAuthTokenRefresher.new.refresh_token(client_name)
end
