ballerina build order-data-service
docker build -t rajkumar/order-data-service:0.1.1 -f order-data-service/docker/Dockerfile .
docker push rajkumar/order-data-service:0.1.1