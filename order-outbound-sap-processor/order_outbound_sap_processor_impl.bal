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

function processOrderToSap (model:OrderDAO orderDAORec) returns boolean {

    model:Order orderRec = check <model:Order> orderDAORec.request;
    time:Time createdAt = time:parse(orderRec.createdAt, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

    xml orders = xml `<ZECOMMORDERS>
            <IDOC BEGIN="1">
            </IDOC>
        </ZECOMMORDERS>`;

    xml ordersHeader = xml `<EDI_DC40 SEGMENT="1">
            <TABNAM>{{orderDAORec.orderNo}}</TABNAM>
            <MANDT>301</MANDT>
            <DOCNUM>0000002342249222</DOCNUM>
            <DOCREL>740</DOCREL>
            <STATUS>30</STATUS>
            <DIRECT>1</DIRECT>
            <OUTMOD>2</OUTMOD>
            <IDOCTYP>ORDERS05</IDOCTYP>
            <CIMTYP>ZECOMMORDERS</CIMTYP>
            <MESTYP>ZECOMMORDERS</MESTYP>
            <STDMES>ZECOMMR</STDMES>
            <SNDPOR>WSO2_ECOMM</SNDPOR>
            <SNDPRT>LS</SNDPRT>
            <SNDPRN>ZECOMM_ECOM</SNDPRN>
            <RCVPOR>WSO2_ECOMM</RCVPOR>
            <RCVPRT>LS</RCVPRT>
            <RCVPRN>Z_SFDC</RCVPRN>
            <CREDAT>{{createdAt.format("yyyyMMdd")}}</CREDAT>
            <CRETIM>{{createdAt.format("HHmmss")}}</CRETIM>
            <ARCKEY>urn:uuid:61AE6D7FBD8922F9561503672302714</ARCKEY>
        </EDI_DC40>`; 

    orders.selectDescendants("IDOC").setChildren(ordersHeader);

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
            <ZECOMMEDKA1 SEGMENT="1">
                <ZADD1>{{getAddress(orderRec.payments[0].billingAddress.countryCode).add1}}</ZADD1>
                <ZADD2>{{getAddress(orderRec.payments[0].billingAddress.countryCode).add2}}</ZADD2>
                <ZADTY />
                <ZCITY>{{getAddress(orderRec.payments[0].billingAddress.countryCode).city}}</ZCITY>
                <ZCOUNTRY>{{getAddress(orderRec.payments[0].billingAddress.countryCode).countryCode}}</ZCOUNTRY>
                <ZPSTLZ>{{getAddress(orderRec.payments[0].billingAddress.countryCode).zip}}</ZPSTLZ>
                <ZNEIGHBOR />
                <ZREGIO>{{getAddress(orderRec.payments[0].billingAddress.countryCode).stateCode}}</ZREGIO>
                <JUR>{{orderRec.payments[0].additionalProperties.jurisdictionCode}}</JUR>
            </ZECOMMEDKA1>
            <ZECOMMEDKA2 SEGMENT="1">
                <ZFNAME>{{orderRec.payments[0].billingAddress.firstName}}</ZFNAME>
                <ZLNAME>{{orderRec.payments[0].billingAddress.lastName}}</ZLNAME>
                <ZTELF1>18006686765</ZTELF1>
            </ZECOMMEDKA2>
            <E1EDKA3 SEGMENT="1" />
        </E1EDKA1>`; 

    xml shippingHeader = xml `<E1EDKA1 SEGMENT="1">
            <PARVW>WE</PARVW>												
            <ZECOMMEDKA1 SEGMENT="1">
                <ZADD1>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).add1}}</ZADD1>
                <ZADD2>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).add2}}</ZADD2>
                <ZADTY />
                <ZCITY>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).city}}</ZCITY>
                <ZCOUNTRY>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).countryCode}}</ZCOUNTRY>
                <ZPSTLZ>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).zip}}</ZPSTLZ>
                <ZNEIGHBOR />
                <ZREGIO>{{getAddress(orderRec.shipments[0].shippingAddress.countryCode).stateCode}}</ZREGIO>
                <JUR>{{orderRec.shipments[0].additionalProperties.jurisdictionCode}}</JUR>
            </ZECOMMEDKA1>
            <ZECOMMEDKA2 SEGMENT="1">
                <ZFNAME>{{orderRec.shipments[0].shippingAddress.firstName}}</ZFNAME>
                <ZLNAME>{{orderRec.shipments[0].shippingAddress.lastName}}</ZLNAME>
                <ZTELF1>18006686765 </ZTELF1>
                <ZTELF2> 9999999999</ZTELF2>
                <ZEMAIL>rajkumarr@wso2.com</ZEMAIL>							
            </ZECOMMEDKA2>
            <E1EDKA3 SEGMENT="1" />
        </E1EDKA1>`;

    xml ecommOrderIdHeader = xml `<E1EDK02 SEGMENT="1">
            <QUALF>001</QUALF>
            <BELNR>{{orderRec.ecommOrderId}}</BELNR>
        </E1EDK02>`;    

    xml E1EDK17Header = xml `<E1EDK17 SEGMENT="1" />`;
    xml E1EDK18Header = xml `<E1EDK18 SEGMENT="1" />`;

    xml payHeader = xml `<E1EDK35 SEGMENT="1">
            <QUALZ>PAY</QUALZ>
            <CUSADD>{{orderRec.payments[0].paymentValue}}</CUSADD>
        </E1EDK35>`;
    
    xml tokenHeader = xml `<E1EDK36 SEGMENT="1">
            <CCNUM>{{orderRec.payments[0].token}}</CCNUM>
            <FAKWR>{{orderRec.payments[0].paymentValue}}</FAKWR>
        </E1EDK36>`;

    xml children = orders.selectDescendants("IDOC").* + paymentHeader + salesOrdHeader + salesOfficeHeader
        + orderSourceHeader + dateHeader + E1EDK04Header + E1EDK05Header + billingHeader + shippingHeader
        + ecommOrderIdHeader + E1EDK17Header + E1EDK18Header + payHeader + tokenHeader;
    orders.selectDescendants("IDOC").setChildren(children);

    foreach shipment in orderRec.shipments {
        time:Time promiseDate = time:parse(shipment.promiseDate, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
        xml cra = xml `<E1EDKT1 SEGMENT="1">
            <TDID>CRA</TDID>
            <TDOBJECT>{{shipment.ecommId}}</TDOBJECT>
            <TDOBNAME>{{promiseDate.format("yyyy-MM-dd'T'HH:mm:ss'Z'")}}</TDOBNAME>
            <E1EDKT2 SEGMENT="1" />
        </E1EDKT1>`;

        time:Time scheduledShipDate = time:parse(shipment.scheduledShipDate, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
        xml ssd = xml `<E1EDKT1 SEGMENT="1">
            <TDID>SSD</TDID>
            <TDOBJECT>{{shipment.ecommId}}</TDOBJECT>
            <TDOBNAME>{{scheduledShipDate.format("yyyy-MM-dd'T'HH:mm:ss'Z'")}}</TDOBNAME>
            <E1EDKT2 SEGMENT="1" />
        </E1EDKT1>`;

        xml shme = xml `<E1EDKT1 SEGMENT="1">
            <TDID>SHME</TDID>
            <TDOBJECT>{{shipment.ecommId}}</TDOBJECT>
            <TDOBNAME>{{shipment.shippingMethod}}</TDOBNAME>
            <E1EDKT2 SEGMENT="1" />
        </E1EDKT1>`;

        children = orders.selectDescendants("IDOC").* + cra + ssd + shme;
        orders.selectDescendants("IDOC").setChildren(children);
    }

    xml contextIdHeader = xml `<E1EDKT1 SEGMENT="1">
            <TDID>ID</TDID>
            <TDOBNAME>{{orderRec.context.id}}</TDOBNAME>
            <E1EDKT2 SEGMENT="1" />
        </E1EDKT1>`;

    children = orders.selectDescendants("IDOC").* + contextIdHeader;
    orders.selectDescendants("IDOC").setChildren(children);

    foreach productLineItem in orderRec.productLineItems {
        xml lineItem = xml `<E1EDP01 SEGMENT="1">
            <POSEX>{{productLineItem.orderLine}}</POSEX>
            <MENGE>{{productLineItem.quantity}}</MENGE>
            <GRKOR>{{productLineItem.additionalProperties.fulfillmentSet}}</GRKOR>
            <WERKS>{{productLineItem.additionalProperties.^"eccCustomAttributes.warehouseId"}}</WERKS>
            <MATNR>{{productLineItem.product.productId}}</MATNR>
            <POSGUID>{{productLineItem.shipmentEcommId}}</POSGUID>
            <UEPOS>{{productLineItem.additionalProperties.parentProductLine}}</UEPOS>
            <E1EDP02 SEGMENT="1" />
            <E1CUREF SEGMENT="1" />
            <E1ADDI1 SEGMENT="1" />
            <E1EDP03 SEGMENT="1" />
            <E1EDP04 SEGMENT="1" />
            <E1EDP05 SEGMENT="1">
                <KSCHL>YBP0</KSCHL>
                <KRATE>{{productLineItem.product.price.basePrice}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>YSNH</KSCHL>
                <KRATE>{{productLineItem.additionalProperties.itemFreight}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>YBPD</KSCHL>
                <KRATE>{{productLineItem.product.price.netPrice}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>MWST</KSCHL>
                <KRATE>{{productLineItem.product.price.tax}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>YBRD</KSCHL>
                <KRATE>{{productLineItem.additionalProperties.levyTax}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>YBRM</KSCHL>
                <KRATE>{{productLineItem.additionalProperties.ecoTax}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP05 SEGMENT="1">
                <KSCHL>TAXR</KSCHL>
                <KRATE>{{productLineItem.additionalProperties.taxRate}}</KRATE>
                <E1EDPS5 SEGMENT="1" />
            </E1EDP05>
            <E1EDP20 SEGMENT="1" />
            <E1EDPA1 SEGMENT="1">
                <E1EDPA3 SEGMENT="1" />
            </E1EDPA1>
            <E1EDP19 SEGMENT="1">
                <QUALF>001</QUALF>
                <IDTNR>{{productLineItem.product.productId}}</IDTNR>
                <KTEXT>{{productLineItem.product.name}}</KTEXT>
            </E1EDP19>
            <E1EDPAD SEGMENT="1">
                <E1TXTH1 SEGMENT="1">
                    <E1TXTP1 SEGMENT="1" />
                </E1TXTH1>
            </E1EDPAD>
            <E1EDP17 SEGMENT="1" />
            <E1EDP18 SEGMENT="1" />
            <E1EDP35 SEGMENT="1" />
            <E1EDPT1 SEGMENT="1">
                <TDID>YR01</TDID>
                <TSSPRAS>EN</TSSPRAS>
                <E1EDPT2 SEGMENT="1">
                    <TDLINE>{{productLineItem.additionalProperties.SN}}</TDLINE>
                </E1EDPT2>
            </E1EDPT1>
            <E1EDPT1 SEGMENT="1">
                <TDID>YR02</TDID>
                <TSSPRAS>EN</TSSPRAS>
                <E1EDPT2 SEGMENT="1">
                    <TDLINE>{{productLineItem.additionalProperties.deviceSerialNumber}}</TDLINE>
                </E1EDPT2>
            </E1EDPT1>							
            <E1EDC01 SEGMENT="1">
                <E1EDC02 SEGMENT="1" />
                <E1EDC03 SEGMENT="1" />
                <E1EDC04 SEGMENT="1" />
                <E1EDC05 SEGMENT="1" />
                <E1EDC06 SEGMENT="1" />
                <E1EDC07 SEGMENT="1" />
                <E1EDCA1 SEGMENT="1" />
                <E1EDC19 SEGMENT="1" />
                <E1EDC17 SEGMENT="1" />
                <E1EDC18 SEGMENT="1" />
                <E1EDCT1 SEGMENT="1">
                    <E1EDCT2 SEGMENT="1" />
                </E1EDCT1>
            </E1EDC01>
        </E1EDP01>`;

        children = orders.selectDescendants("IDOC").* + lineItem;
        orders.selectDescendants("IDOC").setChildren(children);
    }

    xml E1CUCFGHeader = xml `<E1CUCFG SEGMENT="1">
            <E1CUINS SEGMENT="1" />
            <E1CUPRT SEGMENT="1" />
            <E1CUVAL SEGMENT="1" />
            <E1CUBLB SEGMENT="1" />
        </E1CUCFG>`;

    xml E1EDL37Header = xml `<E1EDL37 SEGMENT="1">
            <E1EDL39 SEGMENT="1" />
            <E1EDL38 SEGMENT="1" />
            <E1EDL44 SEGMENT="1" />
        </E1EDL37>`;

    xml tamHeader = xml `<E1EDS01 SEGMENT="1">
            <SUMID>TAM</SUMID>
            <SUMME>{{orderRec.totals.totalAmount}}</SUMME>
        </E1EDS01>`;

    xml tprHeader = xml `<E1EDS01 SEGMENT="1">
            <SUMID>TPR</SUMID>
            <SUMME>{{orderRec.totals.totalMerchandiseCost}}</SUMME>
        </E1EDS01>`;  

    xml ttxHeader = xml `<E1EDS01 SEGMENT="1">
            <SUMID>TTX</SUMID>
            <SUMME>{{orderRec.totals.totalMerchandiseTax}}</SUMME>
        </E1EDS01>`;   

    xml tfrHeader = xml `<E1EDS01 SEGMENT="1">
            <SUMID>TFR</SUMID>
            <SUMME>{{orderRec.totals.additionalProperties.netPrice}}</SUMME>
        </E1EDS01>`;    

    xml tftHeader = xml `<E1EDS01 SEGMENT="1">
            <SUMID>TFT</SUMID>
            <SUMME>{{orderRec.totals.totalShippingTax}}</SUMME>
        </E1EDS01>`;    

    children = orders.selectDescendants("IDOC").* + E1CUCFGHeader + E1EDL37Header + tamHeader + tprHeader + ttxHeader
        + tfrHeader + tftHeader;
    orders.selectDescendants("IDOC").setChildren(children);

    io:println(orders); 

    return true;
}

function getAddress(string countryCode) returns Address {

    Address add;
    if (countryCode == "PZ") {
        add = { 
            countryCode: "US",
            stateCode: "PZ",
            add1: "PZ Addr1",
            add2: "PZ Addr2",
            city: "PZ City",
            zip: "12345"
        };
    } else if (countryCode == "ZI") {
        add = { 
            countryCode: "ZI",
            stateCode: "ZI",
            add1: "ZI Street",
            add2: "ZI Floor",
            city: "ZI City",
            zip: "78967"
        };
    } else {
        add = { 
            countryCode: "US",
            stateCode: "NC",
            add1: "Old Building",
            add2: "Suite 123",
            city: "Charlotte",
            zip: "23242"
        };
    }

    return add;
}