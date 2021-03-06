import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import raj/orders.model as model;

endpoint mb:SimpleTopicSubscriber orderOutboundTopic {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName"),
    acknowledgementMode: "AUTO_ACKNOWLEDGE"
};

service<mb:Consumer> orderOutboundTopicSubscriber bind orderOutboundTopic {

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

                processOrderToSap(orderDAORec);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}