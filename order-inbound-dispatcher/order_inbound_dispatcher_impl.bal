import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/mb;
import raj/orders.model as model;

endpoint mb:SimpleQueueSender orderInboundQueue {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    queueName: config:getAsString("order.mb.queueName")
};

public function addOrder (http:Request req, model:Order orderRec, string kind) returns http:Response {

    http:Response resp = new;
    string ecommOrderId = orderRec.ecommOrderId;
    string orderString = model:orderToString(orderRec);

    log:printInfo("Received " + kind + " order: " + ecommOrderId + ". Payload: \n" + orderString);
    log:printInfo("Queuing " + kind + " order: " + ecommOrderId + " in orderInboundQueue");
    match (orderInboundQueue.createTextMessage(orderString)) {
        
        error err => {
            log:printError("Couldn't queue " + kind + " order: " + ecommOrderId + " in orderInboundQueue", err=err);
            json respPayload = { "Status": "Internal Server Error", "Error": err.message };
            resp.setJsonPayload(untaint respPayload);
            resp.statusCode = http:INTERNAL_SERVER_ERROR_500;
        }
        mb:Message msg => {

            match msg.setStringProperty("kind", kind) {
                error err => {
                    log:printError("Couldn't queue " + kind + " order: " + ecommOrderId + " in orderInboundQueue", err=err);
                    json respPayload = { "Status": "Internal Server Error", "Error": err.message };
                    resp.setJsonPayload(untaint respPayload);
                    resp.statusCode = http:INTERNAL_SERVER_ERROR_500;
                }
                () => {
                    var ret = orderInboundQueue->send(msg);
                    match ret {
                        error err => {
                            log:printError("Couldn't queue " + kind + " order: " + ecommOrderId + " in orderInboundQueue", err=err);
                            json respPayload = { "Status": "Internal Server Error", "Error": err.message };
                            resp.setJsonPayload(untaint respPayload);
                            resp.statusCode = http:INTERNAL_SERVER_ERROR_500;
                        }
                        () => {
                            log:printInfo("Queued " + kind + " order: " + ecommOrderId + " in orderInboundQueue");
                            json respPayload = { "message": "Order: " + ecommOrderId + " queued successfully"};
                            resp.setJsonPayload(untaint respPayload);
                            resp.statusCode = http:OK_200;
                        }
                    }
                }
            }
        }
    }
    
    return resp;
}