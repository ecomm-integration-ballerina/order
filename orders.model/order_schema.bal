public type Order record {
    record {
        string id,
        string partner,
    } context,
    string ecommOrderId,
    string customerEmail,
    string createdAt,
    ProductLineItem[] productLineItems,
    Shipment[] shipments,
    Payment[] payments,
    record {
        string salesOrg,
        string orderSource,
    } partnerAttributes,
    record {
        string totalAmount,
        string totalMerchandiseCost,
        string totalMerchandiseTax,
        string totalShippingTax,
        record {
            string netPrice,
        } additionalProperties,
    } totals,
};

public type ProductLineItem record {
    string id,
    string ecommId,
    string orderLine,
    int quantity,
    string shipmentEcommId,
    Product product,
    record {
        string fulfillmentSet,
        string itemFreight,
        string ^"eccCustomAttributes.warehouseId",
        string parentProductLine,
        string levyTax,
        string ecoTax,
        string taxRate,
        string SN,
        string deviceSerialNumber,
    } additionalProperties,
};

public type Product record {
    string productId,
    string name,
    record {
        string currencyCode,
        float basePrice,
        float netPrice,
        float tax,
    } price,
};

public type Shipment record {
    string id,
    string ecommId,
    string promiseDate,
    string scheduledShipDate,
    string shippingMethod,
    int quantity,
    record {
        string salesOffice,
        string jurisdictionCode,
    } additionalProperties,
    Address shippingAddress,
};

public type Payment record {
    string id,
    string ecommPaymentId,
    string paymentType,
    string paymentValue,
    record {
        string prePayment,
        string ^"eccCustomAttributes.paymentType",
        string jurisdictionCode,
        string billToId,
    } additionalProperties,
    Address billingAddress,
    string token,
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