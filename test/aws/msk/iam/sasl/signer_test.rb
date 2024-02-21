require "test_helper"
require "aws-sdk-core"
require "aws-sdk-kafka"
require "base64"

class Aws::Msk::Iam::Sasl::SignerTest < Minitest::Test

  def setup
    @creds = Aws::Credentials.new("access_key_id", "secret_access", "session_token")
  end

  def test_that_it_has_a_version_number
    refute_nil ::Aws::Msk::Iam::Sasl::Signer::VERSION
  end

  def test_generate_auth_token
    ::Aws::Msk::Iam::Sasl::Signer::Credentials.stub_any_instance :load_default_credentials, @creds do
      token_provider = ::Aws::Msk::Iam::Sasl::Signer::MSKTokenProvider.new(region: "us-east-1")
      signed_url, expiration_time_ms = token_provider.generate_auth_token

      decoded_signed_url = Base64.urlsafe_decode64(signed_url)
      assert_match "https://kafka.us-east-1.amazonaws.com/?Action=kafka-cluster%3AConnect", decoded_signed_url

      uri = URI.parse(decoded_signed_url)
      params = URI.decode_www_form(String(uri.query))
      params = Hash[ params.group_by(&:first).map{ |k,a| [k,a.map(&:last)] } ]

      assert params["Action"] = "kafka-cluster:Connect"
      assert params["X-Amz-Algorithm"] =  "AWS4-HMAC-SHA256"
      assert params["X-Amz-Security-Token"] = "session_token"
      assert params["X-Amz-SignedHeaders"] = "host"
      assert params["X-Amz-Expires"] = "900"
      assert_match "aws-msk-iam-sasl-signer-ruby", params["User-Agent"][0]

      credentials = params["X-Amz-Credential"][0]
      split_credentials = credentials.split("/")
      assert split_credentials[0] = @creds.access_key_id
      assert split_credentials[2] = "us-east-1"
      assert split_credentials[3] = "kafka-cluster"
      assert split_credentials[4] = "aws4_request"

      date_obj = DateTime.strptime(params["X-Amz-Date"][0], "%Y%m%dT%H%M%SZ")
      current_time = Time.now.utc.to_i
      assert_lte date_obj.to_time.to_i, current_time

      actual_expires = 1000 * (params["X-Amz-Expires"].to_i + date_obj.to_time.to_i)
      assert actual_expires = expiration_time_ms

    end
  end
end
