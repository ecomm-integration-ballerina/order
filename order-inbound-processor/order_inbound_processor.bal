import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;

endpoint http:Client orderDataServiceEndpoint {
    url: config:getAsString("order.data.service.url")
};

endpoint mb:SimpleQueueReceiver orderInboundQueueReceiverEp {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    queueName: config:getAsString("order.mb.queueName"),
    acknowledgementMode: "CLIENT_ACKNOWLEDGE"
};

service<mb:Consumer> orderInboundQueueReceiver bind orderInboundQueueReceiverEp {

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

                log:printInfo("Received " + kind + " order: " + ecommOrderId + " from orderInboundQueue");

                if (handleOrder(orderJson, kind)) {
                    consumer->acknowledge(message) but {
                        error err => log:printError("Error in acknowledging " + kind + " order: " 
                            + ecommOrderId + " to orderInboundQueue", err=err)
                    };
                }
            }

            error e => {
                log:printError("Error occurred while reading message from orderInboundQueue", err = e);
            }
        }
    }
}

function handleOrder (json orderJson, string kind) returns boolean {
    
    string ecommOrderId = orderJson.ecommOrderId.toString();
    json payload = {
        "orderNo": orderJson.ecommOrderId,
        "request": orderJson,
        "processFlag": "N",
        "retryCount": 0,
        "errorMessage": "None",
        "orderType": kind
    };

    log:printInfo("Calling orderDataServiceEndpoint for " + kind + " order: " + ecommOrderId);

    http:Request req = new;
    req.setJsonPayload(untaint payload);
    var response = orderDataServiceEndpoint->post("/", req);

    match response {
        http:Response resp => {
            match resp.getJsonPayload() {
                json j => {
                    log:printInfo("Response from orderDataServiceEndpoint for " + kind + 
                        " order: " + ecommOrderId + ". Payload: \n" + j.toString());
                    return true;
                }
                error err => {
                    log:printError("Response from orderDataServiceEndpoint for " + kind + 
                        " order: " + ecommOrderId + " is not a json", err = err);
                    return false;
                }
            }
        }
        error err => {
            log:printError("Error calling orderDataServiceEndpoint for " + kind + 
                " order: " + ecommOrderId, err = err);
            return false;
        }
    }    
}