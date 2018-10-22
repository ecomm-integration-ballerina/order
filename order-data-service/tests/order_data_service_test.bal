import ballerina/test;
import ballerina/io;
import ballerina/http;

boolean serviceStarted;

function startService() {
}

@test:Config {
    before: "startService",
    after: "stopService"
}
function testHealthz() {
    
    endpoint http:Client httpEndpoint { url: "http://localhost:8280/data/order" };
    string expectedResp = "I'm still alive!";

    var response = httpEndpoint->get("/healthz");
    match response {
        http:Response resp => {
            json j = check resp.getJsonPayload();
            test:assertEquals(j.message, expectedResp);
        }
        error err => test:assertFail(msg = "Failed to call the endpoint:");
    }
}

function stopService() {
}