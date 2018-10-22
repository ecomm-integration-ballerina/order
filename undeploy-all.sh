kubectl delete -f order-data-service/kubernetes/order_data_service_deployment.yaml
kubectl delete -f order-inbound-dispatcher/kubernetes/order_inbound_dispatcher_deployment.yaml
kubectl delete -f order-inbound-processor/kubernetes/order_inbound_processor_deployment.yaml
kubectl delete -f order-outbound-dispatcher/kubernetes/order_outbound_dispatcher_deployment.yaml
kubectl delete -f target/kubernetes/order-outbound-bq-processor/order-outbound-bq-processor_deployment.yaml
kubectl delete -f order-outbound-sap-processor/kubernetes/order_outbound_sap_processor_deployment.yaml
kubectl delete -f target/kubernetes/order-outbound-shipment-processor/order-outbound-shipment-processor_deployment.yaml