# aws-msk-iam-sasl-signer with rdkafka

This example demonstrates how to use the `aws-msk-iam-sasl-signer` gem with the [karafka-rdkafka](https://rubygems.org/gems/karafka-rdkafka) gem.


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

Configure the oauthbearer refresh token callback.
Create a producer / consumer / admin client using the delayed start feature.
This allows the client to be registered with the `@clients` hash.
Then start the client using the `start` method.

```ruby
  def self.start!(kafka_config)
    Rdkafka::Config.oauthbearer_token_refresh_callback = method(:refresh_token)
    @producer = Rdkafka::Config.new(kafka_config).producer(native_kafka_auto_start: false)
    @clients[@producer.name] = @producer
    @producer.start
  end
```

At the initial start and every time the token needs to be refreshed, the `refresh_token` method is called.
The callback will receive the name of the client.
Use the `AwsMskIamSaslSigner::MSKTokenProvider` to generate a new token and set it on the client.
Use the `@clients` hash to get the client by name.

```ruby
  def refresh_token(client_name)
    print "refreshing token\n"
    signer = AwsMskIamSaslSigner::MSKTokenProvider.new(region: ENV['AWS_REGION'])
    token = signer.generate_auth_token

    client = Producer.from_name(client_name)
    client.oauthbearer_set_token(
      token: token.token,
      lifetime_ms: token.expiration_time_ms,
      principal_name: 'kafka-cluster'
    )
  end
```
