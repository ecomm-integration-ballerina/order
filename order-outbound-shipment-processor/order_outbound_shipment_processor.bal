import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import ballerinax/kubernetes;
import raj/orders.model as model;

endpoint mb:SimpleTopicSubscriber orderOutboundTopicSubscriberEp {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName")
};

@kubernetes:Deployment {
    name: "order-outbound-shipment-processor-deployment",
    namespace: "default",
    labels: {
        "integration": "order"
    },
    replicas: 1,
    annotations: {
        "prometheus.io/scrape": "true",
        "prometheus.io/path": "/metrics",
        "prometheus.io/port": "9797"
    },
    additionalPorts: {
        "prometheus": 9797
    },
    buildImage: true,
    push: true,
    image: "index.docker.io/$env{DOCKER_USERNAME}/order-outbound-shipment-processor:0.1.0",
    username:"$env{DOCKER_USERNAME}",
    password:"$env{DOCKER_PASSWORD}",
    imagePullPolicy: "Always",
    env: {
        order_mb_host: "b7a-mb-service.default.svc.cluster.local",
        order_mb_port: "5672",
        order_data_service_url: "http://order-data-service-service.default.svc.cluster.local:8280/data/order",
        shipment_data_service_url: "http://shipment-data-service-service.default.svc.cluster.local:8280/data/shipment",
        b7a_observability_tracing_jaeger_reporter_hostname: "jaeger-udp-service.default.svc.cluster.local"
    },
    copyFiles: [
        { 
            source: "./order-outbound-shipment-processor/conf/ballerina.conf", 
            target: "/home/ballerina/ballerina.conf", isBallerinaConf: true 
        }
    ]
}
service<mb:Consumer> orderOutboundTopicSubscriber bind orderOutboundTopicSubscriberEp {

    onMessage(endpoint consumer, mb:Message message) {

        json orderJson;
        match message.getTextMessageContent() {

            string orderString => {
                io:StringReader sr = new(orderString);
                orderJson = check sr.readJson();
                model:OrderDAO orderDAORec = check <model:OrderDAO> orderJson;
                string orderNo = orderDAORec.orderNo;
                string orderType = orderDAORec.orderType;

                log:printInfo("Received " + orderType + " order: " + orderNo + " from orderOutboundTopic");

                processOrderToShipmentAPI(orderDAORec);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}