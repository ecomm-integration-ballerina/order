import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mb;
import ballerina/http;
import ballerina/time;
import raj/orders.model as model;

type Address record {
    string countryCode,
    string stateCode,
    string add1,
    string add2,
    string city,
    string zip,
};

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
                model:OrderDAO orderDAORec = check <model:OrderDAO> orderJson;
                string orderNo = orderDAORec.orderNo;
                string orderType = orderDAORec.orderType;

                log:printInfo("Received order " + orderNo + " of type " + orderType + " from orderOutboundTopic");

                boolean success = processOrderToSap(orderDAORec);
            }

            error e => {
                log:printError("Error occurred while reading message from orderOutboundTopic", err = e);
            }
        }
    }
}

function processOrderToSap (model:OrderDAO orderDAORec) returns boolean {

    model:Order orderRec = check <model:Order> orderDAORec.request;
    time:Time createdAt = time:parse(orderRec.createdAt, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    io:println(orderRec.payments[0].additionalProperties.^"eccCustomAttributes.paymentType");
    xml orders = xml `<ZMOTORDERS>
            <IDOC BEGIN="1">
            </IDOC>
        </ZMOTORDERS>`;

    xml ordersHeader = xml `<EDI_DC40 SEGMENT="1">
            <TABNAM>{{orderDAORec.orderNo}}</TABNAM>
            <MANDT>301</MANDT>
            <DOCNUM>0000002342249222</DOCNUM>
            <DOCREL>740</DOCREL>
            <STATUS>30</STATUS>
            <DIRECT>1</DIRECT>
            <OUTMOD>2</OUTMOD>
            <IDOCTYP>ORDERS05</IDOCTYP>
            <CIMTYP>ZMOTORDERS</CIMTYP>
            <MESTYP>ZMOTORDERS</MESTYP>
            <STDMES>ZMOTOR</STDMES>
            <SNDPOR>WSO2_MOTO</SNDPOR>
            <SNDPRT>LS</SNDPRT>
            <SNDPRN>ZMOTO_ECOM</SNDPRN>
            <RCVPOR>WSO2_MOTO</RCVPOR>
            <RCVPRT>LS</RCVPRT>
            <RCVPRN>Z_SFDC</RCVPRN>
            <CREDAT>{{createdAt.format("yyyyMMdd")}}</CREDAT>
            <CRETIM>{{createdAt.format("HHmmss")}}</CRETIM>
            <ARCKEY>urn:uuid:61AE6D7FBD8922F9561503672302714</ARCKEY>
        </EDI_DC40>`; 

    xml paymentHeader = xml `<E1EDK01 SEGMENT="1">
            <CURCY>{{orderRec.productLineItems[0].product.price.currencyCode}}</CURCY>
            <ZTERM>{{orderRec.payments[0].additionalProperties.prePayment}}</ZTERM>
            <EMPST>{{orderRec.payments[0].additionalProperties.^"eccCustomAttributes.paymentType"}}</EMPST>
        </E1EDK01>`;

    xml salesOrdHeader = xml `<E1EDK14 SEGMENT="1">
            <QUALF>014</QUALF>
            <ORGID>{{orderRec.partnerAttributes.salesOrg}}</ORGID>
        </E1EDK14>`; 

    xml salesOfficeHeader = xml `<E1EDK14 SEGMENT="1">
            <QUALF>016</QUALF>
            <ORGID>{{orderRec.shipments[0].additionalProperties.salesOffice}}</ORGID>
        </E1EDK14>`;   

    xml orderSourceHeader = xml `<E1EDK14 SEGMENT="1">
            <QUALF>019</QUALF>
            <ORGID>{{orderRec.partnerAttributes.orderSource}}</ORGID>
        </E1EDK14>`;  

    xml dateHeader = xml `<E1EDK03 SEGMENT="1">
            <IDDAT>001</IDDAT>
            <DATUM>{{createdAt.format("yyyyMMdd")}}</DATUM>
            <UZEIT>{{createdAt.format("HHmmss")}}</UZEIT>
        </E1EDK03>`;      

    xml E1EDK04Header = xml `<E1EDK04 SEGMENT="1" />`; 
    xml E1EDK05Header = xml `<E1EDK05 SEGMENT="1" />`;  

    xml billingHeader = xml `<E1EDKA1 SEGMENT="1">
            <PARVW>BP</PARVW>
            <ZMOTOEDKA1 SEGMENT="1">
                <ZADD1>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).add1}}</ZADD1>
                <ZADD2>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).add2}}</ZADD2>
                <ZADTY />
                <ZCITY>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).city}}</ZCITY>
                <ZCOUNTRY>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).countryCode}}</ZCOUNTRY>
                <ZPSTLZ>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).zip}}</ZPSTLZ>
                <ZNEIGHBOR />
                <ZREGIO>{{getBillTo(orderRec.payments[0].billingAddress.countryCode).stateCode}}</ZREGIO>
                <JUR>{{orderRec.payments[0].additionalProperties.jurisdictionCode}}</JUR>
            </ZMOTOEDKA1>
            <ZMOTOEDKA2 SEGMENT="1">
                <ZFNAME>{{orderRec.payments[0].billingAddress.firstName}}</ZFNAME>
                <ZLNAME>{{orderRec.payments[0].billingAddress.lastName}}</ZLNAME>
                <ZTELF1>18006686765</ZTELF1>
            </ZMOTOEDKA2>
            <E1EDKA3 SEGMENT="1" />
        </E1EDKA1>`; 

    io:println(billingHeader); 

    return true;
}

function getBillTo(string countryCode) returns Address {

    Address add;
    if (countryCode == "PR") {
        add = { 
            countryCode: "US",
            stateCode: "PR",
            add1: "605-607 Calle Cuevillas",
            add2: "",
            city: "San Juan",
            zip: "00907"
        };
    } else if (countryCode == "VI") {
        add = { 
            countryCode: "VI",
            stateCode: "VI",
            add1: "36-C Strand Street",
            add2: "",
            city: "St Croix",
            zip: "00820"
        };
    } else {
        add = { 
            countryCode: "US",
            stateCode: "IL",
            add1: "222 W. Merchandise Mart Plaza",
            add2: "Suite 1800",
            city: "Chicago",
            zip: "60654"
        };
    }

    return add;
}