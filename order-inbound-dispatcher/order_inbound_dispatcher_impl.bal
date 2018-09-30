import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/mb;

endpoint mb:SimpleQueueSender orderInboundQueue {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    queueName: config:getAsString("order.mb.queueName")
};

public function addOrder (http:Request req, Order orderRec, string kind) returns http:Response {

    http:Response res = new;
    string ecommOrderId = orderRec.ecommOrderId;
    json orderJson = check <json> orderRec;
    string orderString = orderJson.toString();

    log:printInfo("Received order " + ecommOrderId + " of type " + kind + ". Payload: \n" + orderString);
    
    match (orderInboundQueue.createTextMessage(orderString)) {
        
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