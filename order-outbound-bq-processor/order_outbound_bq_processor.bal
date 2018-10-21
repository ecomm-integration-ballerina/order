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
    name: "order-outbound-bq-processor-deployment",
    namespace: "default",
    labels: {
        "integration": "order"
    },
    replicas: 1,
    buildImage: true,
    push: true,
    image: "index.docker.io/$env{DOCKER_USERNAME}/order-outbound-bq-processor:0.1.0",
    username:"$env{DOCKER_USERNAME}",
    password:"$env{DOCKER_PASSWORD}",
    imagePullPolicy: "Always",
    env: {
        order_mb_host: "b7a-mb-service.default.svc.cluster.local",
        order_mb_port: "5672",
        tmc_mb_host: "b7a-mb-service.default.svc.cluster.local",
        tmc_mb_port: "5672",
        bq_url: "http://localhost:8280/bq",
        shipment_data_service_url: "http://shipment-data-service-service.default.svc.cluster.local:8280/data/shipment"
    },
    copyFiles: [
        { 
            source: "./order-outbound-bq-processor/conf/ballerina.conf", 
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

                processOrderToBQAPI(orderJson, orderNo);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}