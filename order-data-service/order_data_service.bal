import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import ballerina/config;
import raj/orders.model as model;

endpoint http:Listener orderDataServiceListener {
    port: 8280
};

@http:ServiceConfig {
    basePath: "/data/order"
}
service<http:Service> orderDataService bind orderDataServiceListener {

    @http:ResourceConfig {
        methods:["GET"],
        path: "/healthz"
    }
    healthz (endpoint outboundEp, http:Request req) {
        http:Response res = new;
        res.setJsonPayload({"message": "I'm still alive!"}, contentType = "application/json");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    } 

    @http:ResourceConfig {
        methods:["POST"],
        path: "/",
        body: "orderJson"
    }
    addOrder (endpoint outboundEp, http:Request req, model:OrderDAO orderJson) {
        http:Response res = addOrder(req, untaint orderJson);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["GET"],
        path: "/"
    }
    getOrders (endpoint outboundEp, http:Request req) {
        http:Response res = getOrders(req);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }   

    @http:ResourceConfig {
        methods:["PUT"],
        path: "/process-flag/",
        body: "orderJson"
    }
    updateProcessFlag (endpoint outboundEp, http:Request req, model:OrderDAO orderJson) {
        http:Response res = updateProcessFlag(req, untaint orderJson);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["PUT"],
        path: "/process-flag/batch/",
        body: "ordersJson"
    }
    batchUpdateProcessFlag (endpoint outboundEp, http:Request req, model:OrdersDAO ordersJson) {
        http:Response res = batchUpdateProcessFlag(req, untaint ordersJson);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }     
}