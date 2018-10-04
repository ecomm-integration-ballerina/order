import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import wso2/soap;
import raj/orders.model as model;

type Address record {
    string countryCode,
    string stateCode,
    string add1,
    string add2,
    string city,
    string zip,
};

int maxRetryCount = config:getAsInt("order.outbound.shipment.maxRetryCount");

endpoint http:Client orderDataServiceEndpoint {
    url: config:getAsString("order.api.url")
};

endpoint http:Client shipmentDataServiceEndpoint {
    url: config:getAsString("shipment.api.url")
};

function processOrderToShipmentAPI (model:OrderDAO orderDAORec) returns boolean {

    int tid = orderDAORec.transactionId;
    string orderNo = orderDAORec.orderNo;
    int retryCount = orderDAORec.retryCount ;

    json payload = createShipmentPayload(orderDAORec);


    http:Request req = new;
    req.setJsonPayload(untaint payload);
    
    log:printInfo("Calling shipmentDataServiceEndpoint.insert / " 
        + tid + " / " + orderNo + ". Payload : " + payload.toString());

    var response = shipmentDataServiceEndpoint->post("/", req);
    io:println(response);
    match response {
        http:Response resp => {
            int httpCode = resp.statusCode;
            if (httpCode == 202) {
                // if (processFlag == "E" && retryCount > maxRetryCount) {
                //     // notifyOperation();
                // }
            }
        }
        error err => {
            log:printError("Error while calling orderDataServiceEndpoint.updateProcessFlag", err = err);
        }
    }

    // soap:SoapRequest soapRequest = {
    //     soapAction: "urn:addOrder",
    //     payload: idoc
    // };

    // log:printInfo("Sending to ecc / " + tid + " / " + orderNo
    //                     + ". Payload : " + io:sprintf("%l", idoc));

    // var details = sapClient->sendReceive("/", soapRequest);

    // match details {
    //     soap:SoapResponse soapResponse => {

    //         xml payload = soapResponse.payload;
    //         if (payload.msg.getTextValue() == "Errored") {

    //             log:printInfo("Failed to send to ecc / " + tid + " / " + orderNo
    //                 + ". Payload : " + io:sprintf("%l", payload));
    //             updateProcessFlag(tid, orderNo, retryCount + 1, "E", "Errored");
    //         } else {

    //             log:printInfo("Sent to ecc / " + tid + " / " + orderNo);
    //             updateProcessFlag(tid, orderNo, retryCount, "C", "Sent to SAP");
    //         }
    //     }
    //     soap:SoapError soapError => {
    //         log:printInfo("Failed to send to ecc / " + tid + " / " + orderNo
    //             + ". Payload : " + soapError.message);
    //         updateProcessFlag(tid, orderNo, retryCount + 1, "E", soapError.message);
    //     }
    // }

    return true;
}

function updateProcessFlag(int tid, string orderNo, int retryCount, string processFlag, string errorMessage) {

    json updateOrder = {
        "transactionId": tid,
        "processFlag": processFlag,
        "retryCount": retryCount,
        "errorMessage": errorMessage
    };

    http:Request req = new;
    req.setJsonPayload(untaint updateOrder);
    
    log:printInfo("Calling orderDataServiceEndpoint.updateProcessFlag / " 
        + tid + " / " + orderNo + ". Payload : " + updateOrder.toString());

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
            log:printError("Error while calling orderDataServiceEndpoint.updateProcessFlag", err = err);
        }
    }
}

function notifyOperation() {
    // sending email alerts
    log:printInfo("Notifying operations");
}

function createShipmentPayload (model:OrderDAO orderDAORec) returns json {

    model:Order orderRec = check <model:Order> orderDAORec.request;
    string shipToCustomerName = orderRec.shipments[0].shippingAddress.firstName;

    json payload = {
        "shipToEmail": orderRec.customerEmail,
        "shipToCustomerName": shipToCustomerName,
        "shipToAddressLine1": orderRec.shipments[0].shippingAddress.address1,
        "shipToAddressLine2": orderRec.shipments[0].shippingAddress.address2,
        "shipToAddressLine3":"",
        "shipToContactNumber": orderRec.shipments[0].shippingAddress.phone,
        "shipToAddressLine4":"",
        "shipToCity": orderRec.shipments[0].shippingAddress.city,
        "shipToState": orderRec.shipments[0].shippingAddress.stateCode,
        "shipToCountry": orderRec.shipments[0].shippingAddress.countryCode,
        "shipToZip": orderRec.shipments[0].shippingAddress.postalCode,
        "shipToCounty": orderRec.shipments[0].additionalProperties.county,
        "shipToProvince": orderRec.shipments[0].shippingAddress.stateCode,
        "billToAddressLine1": orderRec.payments[0].billingAddress.address1,
        "billToAddressLine2": orderRec.payments[0].billingAddress.address2,
        "billToAddressLine3":"",
        "billToAddressLine4":"",
        "billToContactNumber": orderRec.payments[0].billingAddress.phone,
        "billToCity": orderRec.payments[0].billingAddress.city,
        "billToState": orderRec.payments[0].billingAddress.stateCode,
        "billToCountry": orderRec.payments[0].billingAddress.countryCode,
        "billToZip": orderRec.payments[0].billingAddress.postalCode,
        "billToCounty": orderRec.payments[0].additionalProperties.county,
        "billToProvince": orderRec.payments[0].billingAddress.stateCode,
        "orderNo": orderRec.ecommOrderId,
        "lineNumber": "2",
        "contextId": orderRec.context.id
    };

    return payload;
}