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
      params = params.group_by(&:first).transform_values { |a| a.map(&:last) }

      assert_equal "kafka-cluster:Connect", params["Action"][0]
      assert_equal "AWS4-HMAC-SHA256", params["X-Amz-Algorithm"][0]
      assert_equal "session_token", params["X-Amz-Security-Token"][0]
      assert_equal "host", params["X-Amz-SignedHeaders"][0]
      assert_equal "900", params["X-Amz-Expires"][0]
      assert_match "aws-msk-iam-sasl-signer-ruby", params["User-Agent"][0]

      credentials = params["X-Amz-Credential"][0]
      split_credentials = credentials.split("/")
      assert_equal @creds.access_key_id, split_credentials[0]
      assert_equal "us-east-1", split_credentials[2]
      assert_equal "kafka-cluster", split_credentials[3]
      assert_equal "aws4_request", split_credentials[4]

      date_obj = DateTime.strptime(params["X-Amz-Date"][0], "%Y%m%dT%H%M%SZ")
      current_time = Time.now.utc.to_i
      assert_lte date_obj.to_time.to_i, current_time

      actual_expires = 1000 * (params["X-Amz-Expires"][0].to_i + date_obj.to_time.to_i)
      assert_equal expiration_time_ms, actual_expires
    end
  end
end
