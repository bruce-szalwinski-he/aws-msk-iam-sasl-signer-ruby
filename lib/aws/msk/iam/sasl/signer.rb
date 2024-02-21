require "aws-sdk-kafka"
require "aws-sigv4"
require "base64"
require "uri"

module Aws
  module Msk
    module Iam
      module Sasl
        module Signer
          autoload :MSKTokenProvider, "aws/msk/iam/sasl/signer/msk_token_provider"
          autoload :VERSION, "aws/msk/iam/sasl/signer/version"
          autoload :CLI, "aws/msk/iam/sasl/signer/cli"
          autoload :ThorExt, "aws/msk/iam/sasl/signer/thor_ext"
        end
      end
    end
  end
end
