FROM ballerina/ballerina:0.982.0
LABEL maintainer="rajkumarr@wso2.com"

COPY target/order-outbound-bq-processor.balx /home/ballerina
COPY order-outbound-bq-processor/conf/ballerina.conf /home/ballerina

EXPOSE  8280

CMD ballerina run order-outbound-bq-processor.balx