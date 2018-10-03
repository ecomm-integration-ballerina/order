public type Order record {
    Context context,
    string ecommOrderId,
    string customerEmail,
    string createdAt,
    ProductLineItem[] productLineItems,
    Shipment[] shipments,
    Payment[] payments,
    PartnerAttributes partnerAttributes,
    Totals totals,
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
    string shipmentEcommId,
    Product product,
    ProductLineItemsAdditionalProperties additionalProperties,
};

public type Shipment record {
    string id,
    string ecommId,
    string promiseDate,
    string scheduledShipDate,
    string shippingMethod,
    int quantity,
    ShipmentAdditionalProperties additionalProperties,
    Address shippingAddress,
};

public type Payment record {
    string id,
    string ecommPaymentId,
    string paymentType,
    string paymentValue,
    PaymentAdditionalProperties additionalProperties,
    Address billingAddress,
    string token,
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

public type ProductLineItemsAdditionalProperties record {
    string fulfillmentSet,
    string itemFreight,
    string ^"eccCustomAttributes.warehouseId",
    string parentProductLine,
    string levyTax,
    string ecoTax,
    string taxRate,
    string SN,
    string deviceSerialNumber,
};

public type Product record {
    string productId,
    string name,
    Price price,
};

public type Price record {
    string currencyCode,
    float basePrice,
    float netPrice,
    float tax,
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

public type Totals record {
    string totalAmount,
    string totalMerchandiseCost,
    string totalMerchandiseTax,
    string totalShippingTax,
    TotalsAdditionalProperties additionalProperties,
};

public type TotalsAdditionalProperties record {
    string netPrice,
};

public function orderToString(Order o) returns string {
    json orderJson = check <json> o;
    return orderJson.toString();
}