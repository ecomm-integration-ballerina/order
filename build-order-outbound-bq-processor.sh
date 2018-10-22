ballerina build order-outbound-bq-processor
docker build -t rajkumar/order-outbound-bq-processor:0.1.0 -f order-outbound-bq-processor/docker/Dockerfile .
docker push rajkumar/order-outbound-bq-processor:0.1.0
kubectl delete -f order-outbound-bq-processor/kubernetes/order_outbound_bq_processor_deployment.yaml
kubectl create -f order-outbound-bq-processor/kubernetes/order_outbound_bq_processor_deployment.yaml