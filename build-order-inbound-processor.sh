ballerina build order-inbound-processor
docker build -t rajkumar/order-inbound-processor:0.1.0 -f order-inbound-processor/docker/Dockerfile .
docker push rajkumar/order-inbound-processor:0.1.0
kubectl delete -f order-inbound-processor/kubernetes/order_inbound_processor_deployment.yaml
kubectl create -f order-inbound-processor/kubernetes/order_inbound_processor_deployment.yaml