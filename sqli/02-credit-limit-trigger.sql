/*
  Form ORDERITEMS (sales order lines) — trigger PRE-INSERT
  PRE-UPDATE contains:   #INCLUDE ORDERITEMS/PRE-INSERT
  ----------------------------------------------------------
  Blocks a line that would push the customer past the credit limit.

  Customer exposure = open orders of this customer (other orders)
                    + the other lines of this order
                    + the line being saved.

  Credit limit comes from the custom column CUSTOMERS.AIDV_CREDITLIM
  (0 = no limit). To use the customer's standard Obligo instead, replace the first
  SELECT — the rest of the trigger does not change.

  Because the REST API writes through the same forms, orders coming from the web shop
  (see the shopify-erp-order-sync repo, src/adapters/priority.js) are checked by this same trigger.

  Form message 500 (Form Messages, ORDERITEMS):
    "Order exceeds customer credit limit"
*/

:AIDV_LIMIT = 0.0;
SELECT AIDV_CREDITLIM INTO :AIDV_LIMIT
FROM CUSTOMERS
WHERE CUST = :$$.CUST;
GOTO 9 WHERE :AIDV_LIMIT <= 0.0;

/* Other open orders of the same customer */
:AIDV_OPEN = 0.0;
SELECT SUM(ORDERS.TOTPRICE) INTO :AIDV_OPEN
FROM ORDERS, ORDSTATUS
WHERE ORDERS.CUST = :$$.CUST
AND   ORDERS.ORD <> :$$.ORD
AND   ORDSTATUS.ORDSTATUS = ORDERS.ORDSTATUS
AND   ORDSTATUS.CLOSED <> 'Y';

/* The other lines of this order. Quantities are stored as integers ×1000,
   REALQUANT converts them. */
:AIDV_THIS = 0.0;
SELECT SUM(REALQUANT(TQUANT) * PRICE) INTO :AIDV_THIS
FROM ORDERITEMS
WHERE ORD = :$$.ORD
AND   KLINE <> :$.KLINE;

:AIDV_NEW = REALQUANT(:$.TQUANT) * :$.PRICE;

ERRMSG 500 WHERE :AIDV_OPEN + :AIDV_THIS + :AIDV_NEW > :AIDV_LIMIT;

LABEL 9;
