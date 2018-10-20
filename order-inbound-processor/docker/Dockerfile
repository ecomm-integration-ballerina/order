FROM ballerina/ballerina:0.982.0
LABEL maintainer="rajkumarr@wso2.com"

COPY target/order-inbound-processor.balx /home/ballerina
COPY order-inbound-processor/conf/ballerina.conf /home/ballerina

EXPOSE  8280
EXPOSE  9797

CMD ballerina run order-inbound-processor.balx