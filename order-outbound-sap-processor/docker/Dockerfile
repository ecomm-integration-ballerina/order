FROM ballerina/ballerina:0.982.0
LABEL maintainer="rajkumarr@wso2.com"

COPY target/order-outbound-sap-processor.balx /home/ballerina
COPY order-outbound-sap-processor/conf/ballerina.conf /home/ballerina

EXPOSE  8280
EXPOSE  9797

CMD ballerina run order-outbound-sap-processor.balx