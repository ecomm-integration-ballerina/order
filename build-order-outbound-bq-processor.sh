ballerina build order-outbound-bq-processor
kubectl delete -f target/kubernetes/order-outbound-bq-processor/order-outbound-bq-processor_deployment.yaml
kubectl create -f target/kubernetes/order-outbound-bq-processor/order-outbound-bq-processor_deployment.yaml