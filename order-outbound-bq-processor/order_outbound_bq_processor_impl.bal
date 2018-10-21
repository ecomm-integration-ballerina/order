import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import raj/orders.model as model;

int maxRetryCount = config:getAsInt("order.outbound.bq.maxRetryCount");

endpoint http:Client bqEndpoint {
    url: config:getAsString("bq.url")
};

endpoint mb:SimpleQueueSender tmcQueue {
    host: config:getAsString("tmc.mb.host"),
    port: config:getAsInt("tmc.mb.port"),
    queueName: config:getAsString("tmc.mb.queueName")
};

function processOrderToBQAPI (json orderJson, string orderNo) {

    time:Time time = time:currentTime();
    string transactionDate = time.format("yyyyMMddHHmmssSSS");

    json payload = {
        "source_id": "25",
        "destination_id": "135",
        "signal_type_id": "300",
        "transaction_date": transactionDate,
        "data": orderJson
    };

    http:Request req = new;
    req.setJsonPayload(untaint payload);
    
    log:printInfo("Sending to bq, order: " + orderNo + ", payload:\n" + payload.toString());

    var response = bqEndpoint->post("", req);

    boolean success;
    match response {
        http:Response resp => {
            int httpCode = resp.statusCode;
            if (httpCode == 201) {
                log:printInfo("Sent to bq, order: " + orderNo);
                success = true;
            } else {
                log:printInfo("Failed to send to bq, order: " + orderNo);
            }
        }
        error err => {
            log:printError("Error in calling bqEndpoint, order: " + orderNo, err = err);
        }
    }

    if (success) {
        publishToTMCQueue(payload.toString(), orderNo, "SENT");
    } else {
        publishToTMCQueue(payload.toString(), orderNo, "NOT_SENT");
    }
}

function publishToTMCQueue (string req, string orderNo, string status) {

    time:Time time = time:currentTime();
    string transactionDate = time.format("yyyyMMddHHmmssSSS");
    json payload = {
        "externalKey": null,
        "processInstanceID": orderNo,
        "receiverDUNSno":"BQ" ,
        "senderDUNSno": "OPS",
        "transactionDate": transactionDate,
        "version": "V01",
        "transactionFlow": "OUTBOUND",
        "transactionStatus": status,
        "documentID": null,
        "documentName": "ORDER_IMPORT_OPS_BQ",
        "documentNo": "ORDER_IMPORT_OPS_BQ_" + orderNo,
        "documentSize": null,
        "documentStatus": status,
        "documentType": "xml",
        "payload": req,
        "appName": "ORDER_IMPORT_OPS_ECC",
        "documentFilename": null
     };

    log:printInfo("Sending to tmcQueue, order: " + orderNo + ", payload:\n" + payload.toString());

    match (tmcQueue.createTextMessage(payload.toString())) {
        error err => {
            log:printError("Failed to send to tmcQueue, order: " + orderNo, err=err);
        }
        mb:Message msg => {
            var ret = tmcQueue->send(msg);
            match ret {
                error err => {
                    log:printError("Failed to send to tmcQueue, order: " + orderNo, err=err);
                }
                () => {
                    log:printInfo("Sent to tmcQueue, order: " + orderNo);
                }
            }
        }
    }
}