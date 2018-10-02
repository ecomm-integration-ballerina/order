public type OrderDAO record {
    int transactionId,
    string orderNo,
    json request,
    string processFlag,
    int retryCount,
    string errorMessage,
    string createdTime,
    string lastUpdatedTime,
    string orderType,
};

public type OrdersDAO record {
    OrderDAO[] orders,
};

public function orderDaoToString(OrderDAO o) returns string {
    json j = check <json> o;
    return j.toString();
}