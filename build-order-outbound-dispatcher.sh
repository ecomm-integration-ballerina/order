ballerina build order-outbound-dispatcher
docker build -t rajkumar/order-outbound-dispatcher:0.1.1 -f order-outbound-dispatcher/docker/Dockerfile .
docker push rajkumar/order-outbound-dispatcher:0.1.1
kubectl delete -f order-outbound-dispatcher/kubernetes/order_outbound_dispatcher_deployment.yaml
kubectl create -f order-outbound-dispatcher/kubernetes/order_outbound_dispatcher_deployment.yaml