public type Order record {
    int transactionId,
    string orderNo,
    string request,
    string processFlag,
    int retryCount,
    string errorMessage,
    string createdTime,
    string lastUpdatedTime,
    string orderType,
};