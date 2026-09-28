/*
  Procedure AIDV_OPENORD — "Open Orders by Customer"
  --------------------------------------------------
  Steps (Procedure Generator):
    10  INPUT   CST  (link to CUSTOMERS, optional)     FDT / TDT (dates, optional)
    20  SQLI    this file
    30  REPORT  AIDV_OPENORDRPT   (Report Generator, based on table AIDV_OPENORD)

  Custom table AIDV_OPENORD (Table Generator):
    CUST     INT      13   customer (joins to CUSTOMERS.CUST)
    ORDCNT   INT       8   number of open orders
    OPENAMT  REAL     13,2 open order value
    OLDEST   DATE      8   date of the oldest open order

  All custom objects use the AIDV_ prefix, as Priority requires for private development.
*/

/* Customers chosen in the input screen. If the user chose none, LINK returns all. */
LINK CUSTOMERS TO :$.CST;
ERRMSG 1 WHERE :RETVAL <= 0;

/* Report table for this run only — linked, so concurrent users do not collide. */
LINK AIDV_OPENORD TO :$.OUT;
ERRMSG 1 WHERE :RETVAL <= 0;

/* Empty date input = no bound */
:AIDV_FDT = (:$.FDT = 0 ? 01/01/88 : :$.FDT);
:AIDV_TDT = (:$.TDT = 0 ? SQL.DATE8 : :$.TDT);

INSERT INTO AIDV_OPENORD (CUST, ORDCNT, OPENAMT, OLDEST)
SELECT ORDERS.CUST, COUNT(*), SUM(ORDERS.TOTPRICE), MIN(ORDERS.CURDATE)
FROM ORDERS, ORDSTATUS, CUSTOMERS
WHERE ORDSTATUS.ORDSTATUS = ORDERS.ORDSTATUS
AND   ORDSTATUS.CLOSED <> 'Y'                 /* open statuses only */
AND   CUSTOMERS.CUST = ORDERS.CUST            /* restricted by the linked input */
AND   ORDERS.CURDATE BETWEEN :AIDV_FDT AND :AIDV_TDT
AND   ORDERS.ORD > 0
GROUP BY ORDERS.CUST;

UNLINK CUSTOMERS;
/* AIDV_OPENORD stays linked for the REPORT step (it reads :$.OUT). */
