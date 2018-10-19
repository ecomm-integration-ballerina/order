import ballerina/http;
import ballerina/log;
import ballerina/mysql;
import ballerina/config;
// import ballerinax/kubernetes;
import raj/orders.model as model;

// @kubernetes:Service {}
endpoint http:Listener orderDataServiceListener {
    port: 8280
};

// @kubernetes:Deployment {
//     name: "order-data-service",
//     replicas: 1,
//     buildImage: true,
//     push: true,
//     image: "index.docker.io/$env{DOCKER_USERNAME}/order-data-service:0.1.1",
//     username:"$env{DOCKER_USERNAME}",
//     password:"$env{DOCKER_PASSWORD}",
//     imagePullPolicy: "Always",
//     copyFiles: [
//         { 
//             source: "./order-data-service/conf/ballerina.conf", 
//             target: "/home/ballerina/ballerina.conf", isBallerinaConf: true 
//         },
//         {
//             source: "./order-data-service/dependencies/mysql-connector-java-5.1.45-bin.jar",
//             target: "/ballerina/runtime/bre/lib/mysql-connector-java-5.1.45-bin.jar"

//         }
//     ]
// }
@http:ServiceConfig {
    basePath: "/data/order"
}
service<http:Service> orderDataService bind orderDataServiceListener {

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