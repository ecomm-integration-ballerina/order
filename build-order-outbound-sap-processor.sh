ballerina build order-outbound-sap-processor
docker build -t rajkumar/order-outbound-sap-processor:0.1.2 -f order-outbound-sap-processor/docker/Dockerfile .
docker push rajkumar/order-outbound-sap-processor:0.1.2
kubectl delete -f order-outbound-sap-processor/kubernetes/order_outbound_sap_processor_deployment.yaml
kubectl create -f order-outbound-sap-processor/kubernetes/order_outbound_sap_processor_deployment.yaml