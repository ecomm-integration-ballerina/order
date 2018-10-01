import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;

endpoint http:Client orderDataEndpoint {
    url: config:getAsString("order.api.url")
};

endpoint mb:SimpleTopicSubscriber orderOutboundTopic {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName")
};

service<mb:Consumer> orderOutboundTopicSubscriber bind orderOutboundTopic {

    onMessage(endpoint consumer, mb:Message message) {

        json orderJson;
        match message.getTextMessageContent() {

            string orderString => {
                io:StringReader sr = new(orderString);
                orderJson = check sr.readJson();
                Order orderRec = check <Order> orderJson;
                string orderNo = orderRec.orderNo;
                string orderType = orderRec.orderType;

                log:printInfo("Received order " + orderNo + " of type " + orderType + " from orderOutboundTopic");

                handleOrder(orderRec);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}

function handleOrder (Order orderRec) {
    
    json payload = {
        "orderNo": orderJson.ecommOrderId,
        "request": orderJson,
        "processFlag": "N",
        "retryCount": 0,
        "errorMessage": "None",
        "orderType": kind
    };

    http:Request req = new;
    req.setJsonPayload(untaint payload);
    var response = orderDataEndpoint->post("/", req);

    match response {
        http:Response resp => {
            match resp.getJsonPayload() {
                json j => {
                    log:printInfo("Response from orderDataEndpoint : " + j.toString());
                }
                error err => {
                    log:printError("Response from orderDataEndpoint is not a json : " + err.message, err = err);
                }
            }
        }
        error err => {
            log:printError("Error while calling orderDataEndpoint : " + err.message, err = err);
        }
    }    
}