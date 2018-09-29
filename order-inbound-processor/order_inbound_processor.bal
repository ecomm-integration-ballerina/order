import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;

endpoint http:Client orderDataEndpoint {
    url: config:getAsString("order.api.url")
};

endpoint mb:SimpleQueueReceiver orderInboundQueue {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    queueName: config:getAsString("order.mb.queueName")
};

service<mb:Consumer> orderInboundQueueReceiver bind orderInboundQueue {

    onMessage(endpoint consumer, mb:Message message) {

        json orderJson;
        match message.getTextMessageContent() {

            string orderString => {
                io:StringReader sr = new(orderString);
                orderJson = check sr.readJson();
                string ecommOrderId = check <string> orderJson.ecommOrderId;
                
                string kind;
                match message.getStringProperty("kind") {
                    string s => { kind = s; }
                    error => {}
                    () => {}
                }

                log:printInfo("Received order " + ecommOrderId + " of type " + kind + " from orderInboundQueue");

                handleOrder(orderJson, kind);
            }

            error e => {
                log:printError("Error occurred while reading message from orderInboundQueue", err = e);
            }
        }
    }
}

function handleOrder (json orderJson, string kind) {
    
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