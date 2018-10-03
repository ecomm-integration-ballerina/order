import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/log;
import ballerina/sql;
import ballerina/mime;

type orderBatchType string|int|float;

endpoint mysql:Client orderDB {
    host: config:getAsString("order.db.host"),
    port: config:getAsInt("order.db.port"),
    name: config:getAsString("order.db.name"),
    username: config:getAsString("order.db.username"),
    password: config:getAsString("order.db.password"),
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false, serverTimezone:"UTC" }
};

public function addOrder (http:Request req, model:OrderDAO orderJson) returns http:Response {

    string sqlString = "INSERT INTO order_import_request(ORDER_NO,REQUEST,PROCESS_FLAG,
        RETRY_COUNT,ERROR_MESSAGE,ORDER_TYPE) VALUES (?,?,?,?,?,?)";

    log:printInfo("Calling orderDB->insert for OrderNo=" + orderJson.orderNo);

    boolean isSuccessful;
    transaction with retries = 5, oncommit = onCommitFunction, onabort = onAbortFunction {                              
        
        string base64Request = check mime:base64EncodeString(orderJson.request.toString());
        var ret = orderDB->update(sqlString, orderJson.orderNo, base64Request, 
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

public function getOrders (http:Request req)
                    returns http:Response {

    int retryCount = config:getAsInt("order.data.service.default.retryCount");
    int resultsLimit = config:getAsInt("order.data.service.default.resultsLimit");
    string processFlag = config:getAsString("order.data.service.default.processFlag");

    map<string> params = req.getQueryParams();

    if (params.hasKey("processFlag")) {
        processFlag = params.processFlag;
    }

    if (params.hasKey("maxRetryCount")) {
        match <int> params.maxRetryCount {
            int n => {
                retryCount = n;
            }
            error err => {
                throw err;
            }
        }
    }

    if (params.hasKey("maxRecords")) {
        match <int> params.maxRecords {
            int n => {
                resultsLimit = n;
            }
            error err => {
                throw err;
            }
        }
    }

    string sqlString = "select * from order_import_request where PROCESS_FLAG in ( ? ) 
        and RETRY_COUNT <= ? order by TRANSACTION_ID asc limit ?";

    string[] processFlagArray = processFlag.split(",");
    sql:Parameter processFlagPara = { sqlType: sql:TYPE_VARCHAR, value: processFlagArray };

    var ret = orderDB->select(sqlString, model:OrderDAO, loadToMemory = true, processFlagPara, retryCount, resultsLimit);

    http:Response resp = new;
    json[] jsonReturnValue;
    match ret {
        table<model:OrderDAO> tableOrderDAO => {
            foreach orderRec in tableOrderDAO {
                io:StringReader sr = new(check mime:base64DecodeString(orderRec.request.toString()));
                json requestJson = check sr.readJson();
                orderRec.request = requestJson;
                jsonReturnValue[lengthof jsonReturnValue] = check <json> orderRec;
            }
            io:println(jsonReturnValue);
            resp.setJsonPayload(untaint jsonReturnValue);
            resp.statusCode = http:OK_200;
        }
        error err => {
            json respPayload = { "Status": "Internal Server Error", "Error": err.message };
            resp.setJsonPayload(untaint respPayload);
            resp.statusCode = http:INTERNAL_SERVER_ERROR_500;
        }
    }

    

    return resp;
}

public function updateProcessFlag (http:Request req, model:OrderDAO orderJson)
                    returns http:Response {

    log:printInfo("Calling orderDB->updateProcessFlag for TID=" + orderJson.transactionId + 
                    ", OrderNo=" + orderJson.orderNo);
    string sqlString = "UPDATE order_import_request SET PROCESS_FLAG = ?, RETRY_COUNT = ?, ERROR_MESSAGE = ? 
                            where TRANSACTION_ID = ?";

    json resJson;
    boolean isSuccessful;
    transaction with retries = 5, oncommit = onCommitFunction, onabort = onAbortFunction {                              

        var ret = orderDB->update(sqlString, orderJson.processFlag, orderJson.retryCount, 
                                    orderJson.errorMessage, orderJson.transactionId);

        match ret {
            int updatedRows => {
                if (updatedRows < 1) {
                    log:printError("Calling orderDB->updateProcessFlag for TID=" + orderJson.transactionId + 
                                ", OrderNo=" + orderJson.orderNo + " failed", err = ());
                    isSuccessful = false;
                    abort;
                } else {
                    log:printInfo("Calling orderDB->updateProcessFlag for TID=" + orderJson.transactionId + 
                                ", OrderNo=" + orderJson.orderNo + " succeeded");
                    isSuccessful = true;
                }
            }
            error err => {
                log:printError("Calling orderDB->updateProcessFlag for TID=" + orderJson.transactionId 
                    + " failed", err = err);
                isSuccessful = false;
                retry;
            }
        } 

    }     

    int statusCode;
    if (isSuccessful) {
        resJson = { "Status": "ProcessFlag is updated for order : " + orderJson.transactionId };
        statusCode = http:ACCEPTED_202;
    } else {
        resJson = { "Status": "Failed to update ProcessFlag for order : " + orderJson.transactionId };
        statusCode = http:INTERNAL_SERVER_ERROR_500;
    }

    http:Response res = new;
    res.setJsonPayload(resJson);
    res.statusCode = statusCode;
    return res;
}

public function batchUpdateProcessFlag (http:Request req, model:OrdersDAO orders)
                    returns http:Response {

    orderBatchType[][] orderBatches;
    foreach i, orderRec in orders.orders {
        orderBatchType[] ord = [orderRec.processFlag, orderRec.retryCount, orderRec.transactionId];
        orderBatches[i] = ord;
    }
    
    string sqlString = "UPDATE order_import_request SET PROCESS_FLAG = ?, RETRY_COUNT = ? where TRANSACTION_ID = ?";

    log:printInfo("Calling orderDB->batchUpdateProcessFlag");
    
    json resJson;
    boolean isSuccessful;
    transaction with retries = 5, oncommit = onCommitFunction, onabort = onAbortFunction {                              

        var retBatch = orderDB->batchUpdate(sqlString, ... orderBatches);
        match retBatch {
            int[] counts => {
                foreach count in counts {
                    if (count < 1) {
                        log:printError("Calling orderDB->batchUpdateProcessFlag failed", err = ());
                        isSuccessful = false;
                        abort;
                    } else {
                        log:printInfo("Calling orderDB->batchUpdateProcessFlag succeeded");
                        isSuccessful = true;
                    }
                }
            }
            error err => {
                log:printError("Calling orderDB->batchUpdateProcessFlag failed", err = err);
                retry;
            }
        }      
    }     

    int statusCode;
    if (isSuccessful) {
        resJson = { "Status": "ProcessFlags updated"};
        statusCode = http:ACCEPTED_202;
    } else {
        resJson = { "Status": "ProcessFlags not updated" };
        statusCode = http:INTERNAL_SERVER_ERROR_500;
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