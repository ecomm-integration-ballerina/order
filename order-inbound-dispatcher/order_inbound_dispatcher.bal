import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import raj/orders.model as model;

endpoint http:Listener orderImportInboundDispatcherListener {
    port: 8280
};

@http:ServiceConfig {
    basePath: "/order"
}
service<http:Service> orderAPI bind orderImportInboundDispatcherListener {

    @http:ResourceConfig {
        methods:["POST"],
        path: "/",
        consumes: ["text/plain", "application/json"],
        produces: ["application/json"],
        body: "orderRec"
    }
    addB2COrder (endpoint outboundEp, http:Request req, model:Order orderRec) {
        http:Response res = addOrder(req, orderRec, "b2c");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["POST"],
        path: "/b2b",
        consumes: ["text/plain", "application/json"],
        produces: ["application/json"],
        body: "orderRec"
    }
    addB2BOrder (endpoint outboundEp, http:Request req, model:Order orderRec) {
        http:Response res = addOrder(req, orderRec, "b2b");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["POST"],
        path: "/foc",
        consumes: ["text/plain", "application/json"],
        produces: ["application/json"],
        body: "orderRec"
    }
    addFoCOrder (endpoint outboundEp, http:Request req, model:Order orderRec) {
        http:Response res = addOrder(req, orderRec, "foc");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }        
}