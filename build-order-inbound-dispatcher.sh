ballerina build order-inbound-dispatcher
docker build -t rajkumar/order-inbound-dispatcher:0.1.0 -f order-inbound-dispatcher/docker/Dockerfile .
docker push rajkumar/order-inbound-dispatcher:0.1.0