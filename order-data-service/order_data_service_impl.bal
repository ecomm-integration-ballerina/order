import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/log;
import ballerina/sql;

endpoint mysql:Client orderDB {
    host: config:getAsString("order.db.host"),
    port: config:getAsInt("order.db.port"),
    name: config:getAsString("order.db.name"),
    username: config:getAsString("order.db.username"),
    password: config:getAsString("order.db.password"),
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false, serverTimezone:"UTC" }
};

public function addOrder (http:Request req, Order orderJson) returns http:Response {

    string sqlString = "INSERT INTO order_import_request(ORDER_NO,REQUEST,PROCESS_FLAG,
        RETRY_COUNT,ERROR_MESSAGE,ORDER_TYPE) VALUES (?,?,?,?,?,?)";

    log:printInfo("Calling orderDB->insert for OrderNo=" + orderJson.orderNo);

    boolean isSuccessful;
    transaction with retries = 5, oncommit = onCommitFunction, onabort = onAbortFunction {                              

        var ret = orderDB->update(sqlString, orderJson.orderNo, orderJson.request, 
            orderJson.processFlag, orderJson.retryCount, orderJson.errorMessage, 
            orderJson.orderType);

        match ret {
            int insertedRows => {
                if (insertedRows < 1) {
                    log:printError("Calling orderDB->insert for OrderNo=" + orderJson.orderNo 
                        + " failed", err = ());
                    isSuccessful = false;
                    abort;
                } else {
                    log:printInfo("Calling orderDB->insert OrderNo=" + orderJson.orderNo + " succeeded");
                    isSuccessful = true;
                }
            }
            error err => {
                log:printError("Calling orderDB->insert for OrderNo=" + orderJson.orderNo 
                    + " failed", err = err);
                retry;
            }
        }        
    }  

    json resJson;
    int statusCode;
    if (isSuccessful) {
        statusCode = http:OK_200;
        resJson = { "Status": "Order is inserted to the staging database for order : " 
                    + orderJson.orderNo };
    } else {
        statusCode = http:INTERNAL_SERVER_ERROR_500;
        resJson = { "Status": "Failed to insert order to the staging database for order : " 
                    + orderJson.orderNo };
    }
    
    http:Response res = new;
    res.setJsonPayload(resJson);
    res.statusCode = statusCode;
    return res;
}

function onCommitFunction(string transactionId) {
    log:printInfo("Transaction: " + transactionId + " committed");
}

function onAbortFunction(string transactionId) {
    log:printInfo("Transaction: " + transactionId + " aborted");
}