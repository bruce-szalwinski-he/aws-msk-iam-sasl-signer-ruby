require "aws-sdk-kafka"
require "aws-sigv4"
require "base64"
require "uri"

module AwsMskIamSaslSigner
  autoload :MSKTokenProvider, "aws-msk-iam-sasl-signer/msk_token_provider"
  autoload :CredentialsResolver, "aws-msk-iam-sasl-signer/credentials_resolver"
  autoload :VERSION, "aws-msk-iam-sasl-signer/version"
  autoload :CLI, "aws-msk-iam-sasl-signer/cli"
  autoload :ThorExt, "aws-msk-iam-sasl-signer/thor_ext"
end
