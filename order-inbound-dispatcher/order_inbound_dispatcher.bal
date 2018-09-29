import ballerina/http;
import ballerina/log;
import ballerina/mysql;

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
        produces: ["application/json"]
    }
    addB2COrder (endpoint outboundEp, http:Request req) {
        http:Response res = addOrder(req, "b2c");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["POST"],
        path: "/b2b",
        consumes: ["text/plain", "application/json"],
        produces: ["application/json"]
    }
    addB2BOrder (endpoint outboundEp, http:Request req) {
        http:Response res = addOrder(req, "b2b");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }

    @http:ResourceConfig {
        methods:["POST"],
        path: "/foc",
        consumes: ["text/plain", "application/json"],
        produces: ["application/json"]
    }
    addFoCOrder (endpoint outboundEp, http:Request req) {
        http:Response res = addOrder(req, "foc");
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }        
}