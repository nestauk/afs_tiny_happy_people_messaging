require "aws-sdk-core"

Aws.config.update({
  region: "eu-west-2",
  credentials: Aws::Credentials.new(ENV.fetch("AWS_ACCESS_KEY_ID", ""), ENV.fetch("AWS_SECRET_ACCESS_KEY", "")),
})
