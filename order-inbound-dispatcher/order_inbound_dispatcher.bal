import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;
import raj/orders.model as model;

@kubernetes:Service {}
endpoint http:Listener orderImportInboundDispatcherListener {
    port: 8280
};

@kubernetes:Deployment {
    name: "order-inbound-dispatcher",
    replicas: 1,
    buildImage: true,
    push: false,
    image: "index.docker.io/$env{DOCKER_USERNAME}/order-inbound-dispatcher:0.1.0",
    username:"$env{DOCKER_USERNAME}",
    password:"$env{DOCKER_PASSWORD}",
    imagePullPolicy: "Always",
    copyFiles: [
        { 
            source: "./order-inbound-dispatcher/conf/ballerina.conf", 
            target: "/home/ballerina/ballerina.conf", isBallerinaConf: true 
        }
    ]
}
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