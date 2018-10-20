ballerina build order-outbound-sap-processor
docker build -t rajkumar/order-outbound-sap-processor:0.1.0 -f order-outbound-sap-processor/docker/Dockerfile .
docker push rajkumar/order-outbound-sap-processor:0.1.0