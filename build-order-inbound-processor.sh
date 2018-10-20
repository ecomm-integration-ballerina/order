ballerina build order-inbound-processor
docker build -t rajkumar/order-inbound-processor:0.1.0 -f order-inbound-processor/docker/Dockerfile .
docker push rajkumar/order-inbound-processor:0.1.0