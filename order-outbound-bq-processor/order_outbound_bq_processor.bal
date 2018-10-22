import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import raj/orders.model as model;

endpoint mb:SimpleTopicSubscriber orderOutboundTopicSubscriberEp {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName")
};

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