FROM ballerina/ballerina:0.982.0
LABEL maintainer="rajkumarr@wso2.com"

COPY target/order-data-service.balx /home/ballerina
COPY order-data-service/conf/ballerina.conf /home/ballerina

COPY order-data-service/dependencies/packages/dependencies/* /ballerina/runtime/bre/lib/

EXPOSE  8280
EXPOSE  9797

CMD ballerina run order-data-service.balx