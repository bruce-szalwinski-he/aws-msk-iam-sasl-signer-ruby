# aws-msk-iam-sasl-signer with rdkafka

This example demonstrates how to use [aws-msk-iam-sasl-signer-ruby](https://github.com/bruce-szalwinski-he/aws-msk-iam-sasl-signer-ruby) with the [waterdrop](https://github.com/karafka/waterdrop).


## Usage

```bash
export AWS_REGION=us-west-2
export AWS_ACCOUNT_ID=123456789012
export CLUSTER_NAME=my-cluster
export CLUSTER_UUID=abc
export KAFKA_TOPIC=my-topic

# Create AWS MSK Cluster with IAM authentication enabled
# https://docs.aws.amazon.com/msk/latest/developerguide/msk-iam.html

export CLUSTER_ARN="arn:aws:kafka:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${CLUSTER_NAME}/${CLUSTER_UUID}"
export KAFKA_BROKERS=$(aws kafka get-bootstrap-brokers --cluster-arn ${CLUSTER_ARN} | jq -r ".BootstrapBrokerStringSaslIam")
bundle install
bundle exec ruby example.rb
```

## Key Things to Know

Create a producer / consumer / admin client
Either configure the oauth token provider listener with a class that responds to the `on_oauthbearer_token_refresh` or subscribe to the `oauthbearer.token_refresh` event.

```ruby
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
```

Every time the token needs to be refreshed, the `on_oauthbearer_token_refresh` method will be called.
Use the `AwsMskIamSaslSigner::MSKTokenProvider` to generate a new token and set it on the `event[:bearer]` using the `oauthbearer_set_token` method.


```ruby
  def on_oauthbearer_token_refresh(event)
  signer = AwsMskIamSaslSigner::MSKTokenProvider.new(region: ENV.fetch("AWS_REGION", nil))
  token = signer.generate_auth_token

  event[:bearer].oauthbearer_set_token(
    token: token.token,
    lifetime_ms: token.expiration_time_ms,
    principal_name: 'kafka-cluster'
  )
end
```
