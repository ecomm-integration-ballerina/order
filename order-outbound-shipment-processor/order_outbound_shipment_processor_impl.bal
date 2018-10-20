import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import raj/orders.model as model;

int maxRetryCount = config:getAsInt("order.outbound.shipment.maxRetryCount");

endpoint http:Client orderDataServiceEndpoint {
    url: config:getAsString("order.data.service.url")
};

endpoint http:Client shipmentDataServiceEndpoint {
    url: config:getAsString("shipment.data.service.url")
};

function processOrderToShipmentAPI (model:OrderDAO orderDAORec) {

    int tid = orderDAORec.transactionId;
    string orderNo = orderDAORec.orderNo;
    int retryCount = orderDAORec.retryCount ;

    json payload = createShipmentPayload(orderDAORec);

    io:println(payload);
    http:Request req = new;
    req.setJsonPayload(untaint payload);
    
    log:printInfo("Calling shipmentDataServiceEndpoint to insert tid: " 
        + tid + ", order: " + orderNo + ", payload:\n" + payload.toString());

    var response = shipmentDataServiceEndpoint->post("/batch", req);

    match response {
        http:Response resp => {
            int httpCode = resp.statusCode;
            if (httpCode == 200) {
                log:printInfo("Sent to shipmentDataServiceEndpoint to insert tid: " + tid + 
                    ", order: " + orderNo);
            } else {
                log:printInfo("Failed to send to shipmentDataServiceEndpoint to insert tid: " + tid + 
                    ", order: " + orderNo);
            }
        }
        error err => {
            log:printError("Error in calling shipmentDataServiceEndpoint to insert tid: " + tid + 
                    ", order: " + orderNo, err = err);
        }
    }
}

function createShipmentPayload (model:OrderDAO orderDAORec) returns json {

    model:Order orderRec = check <model:Order> orderDAORec.request;

    json jsonPayload;
    int lines = 0;
    foreach i, shipment in orderRec.shipments {
        foreach lineItemId in shipment.productLineItemIds {
            string shipToCustomerName = orderRec.shipments[i].shippingAddress.firstName;
            json payload = {
                "shipToEmail": orderRec.customerEmail,
                "shipToCustomerName": shipToCustomerName,
                "shipToAddressLine1": orderRec.shipments[i].shippingAddress.address1,
                "shipToAddressLine2": orderRec.shipments[i].shippingAddress.address2,
                "shipToAddressLine3":"",
                "shipToContactNumber": orderRec.shipments[i].shippingAddress.phone,
                "shipToAddressLine4":"",
                "shipToCity": orderRec.shipments[i].shippingAddress.city,
                "shipToState": orderRec.shipments[i].shippingAddress.stateCode,
                "shipToCountry": orderRec.shipments[i].shippingAddress.countryCode,
                "shipToZip": orderRec.shipments[i].shippingAddress.postalCode,
                "shipToCounty": orderRec.shipments[i].additionalProperties.county,
                "shipToProvince": orderRec.shipments[i].shippingAddress.stateCode,
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
                "lineNumber": lineItemId,
                "contextId": orderRec.context.id
            };

            jsonPayload.shipments[lines] = payload;
            lines++;
        }
    }

    return jsonPayload;
}