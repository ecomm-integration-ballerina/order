import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/mb;

endpoint mb:SimpleQueueSender orderInboundQueue {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    queueName: config:getAsString("order.mb.queueName")
};

public function addOrder (http:Request req, string kind) returns http:Response {

    http:Response res = new;
    string contentType = req.getContentType();
    json orderJson;
    if (contentType.contains("text/plain")) {
        
        match <json> req.getTextPayload() {
            json j => orderJson = j;
            error => {
                json resPayload = {
                    "message": "Non json payload is not accepted"
                };
                res.setJsonPayload(untaint resPayload, contentType = "application/json");
                res.statusCode = http:BAD_REQUEST_400;  
                return res;  
            }
        }
        
    } else if (contentType.contains("application/json")) {

        match <json> req.getJsonPayload() {
            json j => orderJson = j;
            error => {
                json resPayload = {
                    "message": "Non json payload is not accepted"
                };
                res.setJsonPayload(untaint resPayload, contentType = "application/json");
                res.statusCode = http:BAD_REQUEST_400;
                return res;    
            }
        }

    } else {

        json resPayload = {
            "message": "Content-Type " + contentType + " is not accepted"
        };
        res.setJsonPayload(untaint resPayload, contentType = "application/json");
        res.statusCode = http:BAD_REQUEST_400;
        return res;
    }

    string ecommOrderId = check <string> orderJson.ecommOrderId;

    // log:printInfo("Received order " + ecommOrderId + " of type " + kind + ".\nPayload: " + orderJson.toString());
    log:printInfo("Received order " + ecommOrderId + " of type " + kind);
    
    match (orderInboundQueue.createTextMessage(orderJson.toString())) {
        
        error e => {
            log:printError("Error occurred while creating message", err = e);
        }
        mb:Message msg => {
            match msg.setStringProperty("kind", kind) {
                error e => {
                    log:printError("Error setting kind property", err = e);
                }
                () => {}
            }

            log:printInfo("Inserting order " + ecommOrderId + " of type " + kind + " into orderInboundQueue");
            orderInboundQueue->send(msg) but {
                error e => log:printError("Error occurred while sending message to orderInboundQueue", err = e)
            };
        }
    }
    
    return res;
}