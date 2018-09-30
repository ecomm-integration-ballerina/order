type Context record {
    string id,
    string partner,
};

type ProductLineItem record {
    string id,
    string ecommId,
    string orderLine,
    int quantity,
};

type Shipment record {
    string id,
    string ecommId,
    string promiseDate,
    string scheduledShipDate,
    string shippingMethod,
    int quantity,
};

type Order record {
    Context context,
    string ecommOrderId,
    string customerEmail,
    ProductLineItem[] productLineItems,
    Shipment[] shipments,
};