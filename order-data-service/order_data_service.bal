import ballerina/http;
import ballerina/log;
import ballerina/mysql;

endpoint http:Listener orderListener {
    port: 8281
};

@http:ServiceConfig {
    basePath: "/order"
}
service<http:Service> orderDataAPI bind orderListener {

    @http:ResourceConfig {
        methods:["POST"],
        path: "/",
        body: "orderJson"
    }
    addOrder (endpoint outboundEp, http:Request req, OrderDAO orderJson) {
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
        path: "/process-flag/batch/",
        body: "orders"
    }
    batchUpdateProcessFlag (endpoint outboundEp, http:Request req, OrdersDAO orders) {
        http:Response res = batchUpdateProcessFlag(req, orders);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }     
}