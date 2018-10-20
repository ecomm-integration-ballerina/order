FROM ballerina/ballerina:0.982.0
LABEL maintainer="rajkumarr@wso2.com"

COPY target/order-inbound-dispatcher.balx /home/ballerina
COPY order-inbound-dispatcher/conf/ballerina.conf /home/ballerina

CMD ballerina run order-inbound-dispatcher.balx
