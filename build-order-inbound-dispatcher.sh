ballerina build order-inbound-dispatcher
docker build -t rajkumar/order-inbound-dispatcher:0.1.0 -f order-inbound-dispatcher/docker/Dockerfile .
docker push rajkumar/order-inbound-dispatcher:0.1.0
kubectl delete -f order-inbound-dispatcher/kubernetes/order_inbound_dispatcher_deployment.yaml
kubectl create -f order-inbound-dispatcher/kubernetes/order_inbound_dispatcher_deployment.yaml
kubectl create -f order-inbound-dispatcher/kubernetes/order_inbound_dispatcher_svc.yaml