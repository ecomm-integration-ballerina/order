public type Order record {
    Context context,
    string ecommOrderId,
    string customerEmail,
    string createdAt,
    ProductLineItem[] productLineItems,
    Shipment[] shipments,
    Payment[] payments,
    PartnerAttributes partnerAttributes,
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
    Product product,
};

public type Shipment record {
    string id,
    string ecommId,
    string promiseDate,
    string scheduledShipDate,
    string shippingMethod,
    int quantity,
    ShipmentAdditionalProperties additionalProperties,
};

public type Payment record {
    string id,
    string ecommPaymentId,
    string paymentType,
    PaymentAdditionalProperties additionalProperties,
    Address billingAddress,
};

public type PaymentAdditionalProperties record {
    string prePayment,
    string ^"eccCustomAttributes.paymentType",
    string jurisdictionCode,
};

public type ShipmentAdditionalProperties record {
    string salesOffice,
    string jurisdictionCode,
};

public type Product record {
    string name,
    Price price,
};

public type Price record {
    string currencyCode,
};

public type PartnerAttributes record {
    string salesOrg,
    string orderSource,
};

public type Address record {
    string countryCode,
    string firstName,
    string lastName,
};

public function orderToString(Order o) returns string {
    json orderJson = check <json> o;
    return orderJson.toString();
}