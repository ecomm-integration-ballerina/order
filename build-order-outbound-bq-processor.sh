ballerina build order-outbound-bq-processor
docker build -t rajkumar/oorder-outbound-bq-processor:0.1.0 -f oorder-outbound-bq-processor/docker/Dockerfile .
docker push rajkumar/oorder-outbound-bq-processor:0.1.0
kubectl delete -f target/kubernetes/order-outbound-bq-processor/order-outbound-bq-processor_deployment.yaml
kubectl create -f target/kubernetes/order-outbound-bq-processor/order-outbound-bq-processor_deployment.yaml