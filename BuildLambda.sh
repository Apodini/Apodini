#!/bin/bash

# docker run \
#   --rm \
#   --volume "$(pwd)/:/src/" \
#   --workdir "/src/" \
#   swift:5.3-amazonlinux2 \
#   /bin/bash -c "yum -y install libuuid-devel libicu-devel libedit-devel libxml2-devel sqlite-devel python-devel ncurses-devel curl-devel openssl-devel libtool jq tar zip && swift build --product TestWebServiceAWS -c debug && package-lambda.sh TestWebServiceAWS"

set -ex

docker run \
  --rm \
  --volume "$(pwd):/src/" \
  --workdir "/src/" \
  builder \
  bash -cl "swift build --product TestWebServiceAWS && ./package-lambda.sh TestWebServiceAWS"

# aws s3 sync --delete .build/lambda/TestWebServiceAWS/lambda.zip s3://apodini/lambda-code/TestWebServiceAWS.zip

aws s3 cp .build/lambda/TestWebServiceAWS/lambda.zip s3://apodini/lambda-code/TestWebServiceAWS.zip

aws --region eu-central-1 lambda update-function-code \
  --function-name apodini-test-function \
  --s3-bucket apodini \
  --s3-key lambda-code/TestWebServiceAWS.zip
#  --zip-file fileb://.build/lambda/TestWebServiceAWS/lambda.zipt
