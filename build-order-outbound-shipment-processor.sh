ballerina build order-outbound-shipment-processor
kubectl delete -f target/kubernetes/order-outbound-shipment-processor/order-outbound-shipment-processor_deployment.yaml
kubectl create -f target/kubernetes/order-outbound-shipment-processor/order-outbound-shipment-processor_deployment.yaml