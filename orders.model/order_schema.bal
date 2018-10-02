public type Order record {
    Context context,
    string ecommOrderId,
    string customerEmail,
    ProductLineItem[] productLineItems,
    Shipment[] shipments,
};

public type Context record {
    string id,
    string partner,
};

public type ProductLineItem record {
    string id,
    string ecommId,
    string orderLine,
    int quantity,
};

public type Shipment record {
    string id,
    string ecommId,
    string promiseDate,
    string scheduledShipDate,
    string shippingMethod,
    int quantity,
};

public function orderToString(Order o) returns string {
    json orderJson = check <json> o;
    return orderJson.toString();
}