import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import raj/orders.model as model;

endpoint http:Client orderDataEndpoint {
    url: config:getAsString("order.api.url")
};

endpoint mb:SimpleTopicSubscriber orderOutboundTopic {
    host: config:getAsString("order.mb.host"),
    port: config:getAsInt("order.mb.port"),
    topicPattern: config:getAsString("order.mb.topicName")
};

service<mb:Consumer> orderOutboundTopicSubscriber bind orderOutboundTopic {

    onMessage(endpoint consumer, mb:Message message) {

        json orderJson;
        match message.getTextMessageContent() {

            string orderString => {
                io:StringReader sr = new(orderString);
                orderJson = check sr.readJson();
                model:OrderDAO orderRec = check <model:OrderDAO> orderJson;
                string orderNo = orderRec.orderNo;
                string orderType = orderRec.orderType;

                log:printInfo("Received order " + orderNo + " of type " + orderType + " from orderOutboundTopic");

                // processOrderToSap(orderRec);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}

// function processOrderToSap (model:Order orderRec) returns boolean {

//     xml orders = xml `<ZMOTORDERS>
//             <IDOC BEGIN="1">
//             </IDOC>
//         </ZMOTORDERS>`;

//     xml ordersHeader = xml `<EDI_DC40 SEGMENT="1">
//             <TABNAM>{{orderRec.orderNo}}</TABNAM>
//             <MANDT>301</MANDT>
//             <DOCNUM>0000002342249222</DOCNUM>
//             <DOCREL>740</DOCREL>
//             <STATUS>30</STATUS>
//             <DIRECT>1</DIRECT>
//             <OUTMOD>2</OUTMOD>
//             <IDOCTYP>ORDERS05</IDOCTYP>
//             <CIMTYP>ZMOTORDERS</CIMTYP>
//             <MESTYP>ZMOTORDERS</MESTYP>
//             <STDMES>ZMOTOR</STDMES>
//             <SNDPOR>WSO2_MOTO</SNDPOR>
//             <SNDPRT>LS</SNDPRT>
//             <SNDPRN>ZMOTO_ECOM</SNDPRN>
//             <RCVPOR>WSO2_MOTO</RCVPOR>
//             <RCVPRT>LS</RCVPRT>
//             <RCVPRN>Z_SFDC</RCVPRN>
//             <CREDAT>20180927</CREDAT>
//             <CRETIM>202544</CRETIM>
//             <ARCKEY>urn:uuid:61AE6D7FBD8922F9561503672302714</ARCKEY>
//         </EDI_DC40>`;    

//     return true;
// }