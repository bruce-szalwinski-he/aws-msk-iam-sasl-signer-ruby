# frozen_string_literal: true

module AwsMskIamSaslSigner
  class CredentialResolver
    def from_credential_provider_chain(region)
      client = Aws::Kafka::Client.new(region: region)
      raise "No credentials found" unless client.config.credentials

      client.config.credentials
    end

    def from_profile(profile)
      Aws::SharedCredentials.new(profile_name: profile)
    end

    def from_role_arn(role_arn:, session_name:)
      sts = Aws::STS::Client.new
      sts.assume_role({ role_arn: role_arn, role_session_name: session_name })
    end
  end
end
