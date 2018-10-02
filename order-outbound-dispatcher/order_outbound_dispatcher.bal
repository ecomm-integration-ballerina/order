import ballerina/log;
import ballerina/http;
import ballerina/config;
import ballerina/task;
import ballerina/runtime;
import ballerina/io;
import ballerina/mb;
import raj/orders.model as model;

endpoint mb:SimpleTopicPublisher orderOutboundPublisher {
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

function main(string... args) {

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
                    io:println(jsonOrderArray);
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
                    throw err;
                }
            }
        }
        error err => {
            log:printError("Error while calling orderDataServiceEndpoint : " + 
                            err.message, err = err);
            throw err;
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

        log:printInfo("Publishing to topic : " + orderNo + 
                        ". Payload : " + jsonPayload.toString());

        match (orderOutboundPublisher.createTextMessage(jsonPayload.toString())) {
            
            error e => {
                log:printError("Error occurred while creating message", err = e);
            }

            mb:Message msg => {
                log:printInfo("Publishing order " + orderNo + " of type " + orderType + " into orderOutboundTopic");
                orderOutboundPublisher->send(msg) but {
                    error e => log:printError("Error occurred while sending message to orderOutboundTopic", err = e)
                };
            }
        }
    }
}

function handleError(error e) {
    log:printError("Error in Order Outbound Dispatcher ETL", err = e);
}

function batchUpdateProcessFlagsToP (model:OrderDAO[] orders) returns boolean{

    json batchUpdateProcessFlagsPayload;
    foreach i, orderRec in orders {
        json updateProcessFlagPayload = {
            "transactionId": orderRec.transactionId,
            "retryCount": orderRec.retryCount,
            "processFlag": "P"           
        };
        batchUpdateProcessFlagsPayload.orders[i] = updateProcessFlagPayload;
    }

    http:Request req = new;
    req.setJsonPayload(untaint batchUpdateProcessFlagsPayload);

    var response = orderDataServiceEndpoint->put("/process-flag/batch/", req);

    boolean success;
    match response {
        http:Response resp => {
            if (resp.statusCode == 202) {
                success = true;
            }
        }
        error err => {
            log:printError("Error while calling orderDataServiceEndpoint.batchUpdateProcessFlags", err = err);
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

    var response = orderDataServiceEndpoint->put("/process-flag/", req);

    match response {
        http:Response resp => {
            int httpCode = resp.statusCode;
            if (httpCode == 202) {
                if (processFlag == "E" && retryCount > maxRetryCount) {
                    notifyOperation();
                }
            }
        }
        error err => {
            log:printError("Error while calling orderDataServiceEndpoint", err = err);
        }
    }
}

function notifyOperation()  {
    // sending email alerts
    log:printInfo("Notifying operations");
}
