import ballerina/log;
import ballerina/http;
import ballerina/config;
import ballerina/task;
import ballerina/runtime;
import ballerina/io;
import ballerina/mb;
import raj/orders.model as model;

endpoint mb:SimpleTopicPublisher orderOutboundTopicPublisherEp {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName")
};

endpoint http:Client orderDataServiceEndpoint {
    url: config:getAsString("order.data.service.url")
};

int count;
task:Timer? timer;
int interval = config:getAsInt("order.outbound.dispatcher.task.interval");
int delay = config:getAsInt("order.outbound.dispatcher.task.delay");
int maxRetryCount = config:getAsInt("order.outbound.dispatcher.task.maxRetryCount");
int maxRecords = config:getAsInt("order.outbound.dispatcher.task.maxRecords");

public function main(string... args) {

    (function() returns error?) onTriggerFunction = doOrderOutboundDispatcherETL;

    function(error) onErrorFunction = handleError;

    log:printInfo("Starting Order Outbound Dispatcher ETL");

    timer = new task:Timer(onTriggerFunction, onErrorFunction,
        interval, delay = delay);

    timer.start();
    runtime:sleep(200000);
}

function doOrderOutboundDispatcherETL() returns  error? {

    log:printInfo("Calling orderDataServiceEndpoint to fetch orders");

    var response = orderDataServiceEndpoint->get("?maxRecords=" + maxRecords
            + "&maxRetryCount=" + maxRetryCount + "&processFlag=N,E");

    match response {
        http:Response resp => {
            match resp.getJsonPayload() {
                json jsonOrderArray => { 

                    model:OrderDAO[] orders = check <model:OrderDAO[]> jsonOrderArray;
                    // terminate the flow if no orders found
                    if (lengthof orders == 0) {
                        return;
                    }
                    // update process flag to P in DB so that next ETL won't fetch these again
                    boolean success = batchUpdateProcessFlagsToP(orders);
                    // send orders to orderOutboundTopic
                    if (success) {
                        publishOrdersToTopic(orders);
                    }
                }
                error err => {
                    log:printError("Response from orderDataServiceEndpoint is not a json : " + 
                                    err.message, err = err);
                }
            }
        }
        error err => {
            log:printError("Error while calling orderDataServiceEndpoint : " + 
                            err.message, err = err);
        }
    }

    return ();
}

function publishOrdersToTopic (model:OrderDAO[] orders) {

    foreach orderRec in orders {

        int tid = orderRec.transactionId;
        string orderNo = orderRec.orderNo;
        int retryCount = orderRec.retryCount;
        string orderType = orderRec.orderType;
       
        json jsonPayload = check <json> orderRec;

        log:printInfo("Publishing " + orderType + " order: " + orderNo + 
                        " to orderOutboundTopic. Payload: \n" + jsonPayload.toString());

        match (orderOutboundTopicPublisherEp.createTextMessage(jsonPayload.toString())) {
            
            error e => {
                log:printError("Error occurred while creating message for " + orderType + 
                    " order: " + orderNo, err = e);
            }

            mb:Message msg => {
                orderOutboundTopicPublisherEp->send(msg) but {
                    error e => log:printError("Error in publishing " + orderType + " order: " 
                        + orderNo + " to orderOutboundTopic", err = e)
                };
            }
        }
    }
}

function handleError(error err) {
    log:printError("Error in Order Outbound Dispatcher ETL", err = err);
}

function batchUpdateProcessFlagsToP (model:OrderDAO[] orders) returns boolean{

    json batchUpdateProcessFlagsPayload;
    string tids;
    foreach i, orderRec in orders {
        json updateProcessFlagPayload = {
            "transactionId": orderRec.transactionId,
            "retryCount": orderRec.retryCount,
            "processFlag": "P"           
        };
        batchUpdateProcessFlagsPayload.orders[i] = updateProcessFlagPayload;
        if (i == 0) {
            tids = <string> orderRec.transactionId;
        } else {
            tids = tids + ", " + <string> orderRec.transactionId;
        }
    }

    log:printInfo("Calling orderDataServiceEndpoint to batchUpdate records of tids: " + tids + " to P");

    http:Request req = new;
    req.setJsonPayload(untaint batchUpdateProcessFlagsPayload);

    var response = orderDataServiceEndpoint->put("/process-flag/batch/", req);

    boolean success;
    match response {
        http:Response resp => {
            if (resp.statusCode == 202) {
                success = true;
            } else {
                log:printError("Couldn't batchUpdate records of tids: " 
                    + tids + " to P", err = ());  
            }
        }
        error err => {
            log:printError("Error in calling orderDataServiceEndpoint to batchUpdate records of tids: " 
                + tids + " to P", err = err);
        }
    }

    return success;
}

function updateProcessFlag(int tid, int retryCount, string processFlag, string errorMessage) {

    json updateOrder = {
        "transactionId": tid,
        "processFlag": processFlag,
        "retryCount": retryCount,
        "errorMessage": errorMessage
    };

    http:Request req = new;
    req.setJsonPayload(untaint updateOrder);

    log:printInfo("Calling orderDataServiceEndpoint to update records of tid: " + tid + " to " + processFlag);

    var response = orderDataServiceEndpoint->put("/process-flag/", req);

    match response {
        http:Response resp => {
            int httpCode = resp.statusCode;
            if (httpCode == 202) {
                if (processFlag == "E" && retryCount > maxRetryCount) {
                    notifyOperation();
                }
            } else {
                log:printError("Couldn't update records of tid: " + tid + " to " + processFlag, err = ());  
            }
        }
        error err => {
            log:printError("Error in calling orderDataServiceEndpoint to update records of tid: " 
                + tid + " to " + processFlag, err = err);
        }
    }
}

function notifyOperation()  {
    // sending email alerts
    log:printInfo("Notifying operations");
}
