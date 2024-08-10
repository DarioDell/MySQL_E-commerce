USE import;



 -- 1.  Are there duplicate clients? and duplicate products?
SELECT 
    'customer' AS tableName,
    customerNumber,
    COUNT(*) AS count
FROM customers
GROUP BY customerNumber
HAVING COUNT(*) > 1
UNION
SELECT 
    'products' AS tableName,
    productName,
    COUNT(*) AS count
FROM products
GROUP BY productName
HAVING COUNT(*) > 1;





-- 2. How many of different nationalities are about the clients?
SELECT DISTINCT country, COUNT(*) FROM customers
GROUP BY country
ORDER BY COUNT(*) DESC;





-- 3. How many distinct products does the company have?
SELECT COUNT( DISTINCT productName) AS total_product FROM products;





-- 4. Quantity of products offered by each product line
SELECT DISTINCT(productLine), 
	   COUNT(productName) AS quantity_product
FROM products
GROUP BY productLine;





-- 5. Annual sales summary: Total amount per year, maximum amount and minimum amount per year
SELECT YEAR(paymentDate) AS year, 
	   ROUND(SUM(amount),2) AS annual_amount, 
	   MAX(amount) AS monto_max, 
       MIN(amount) AS monto_min
FROM payments
GROUP BY year
ORDER BY annual_amount DESC;






-- 6. Calculate the quantity and percentage of products in each of the warehouses
SELECT w.warehouseName, COUNT(p.productName) As product_per_warehouse,
	   ROUND(COUNT(p.productName) * 100.0 / total_products.total, 2) AS percentage_of_total
FROM warehouses w
JOIN products p ON w.warehouseCode = p.warehouseCode
JOIN (SELECT COUNT(*) AS total FROM products) AS total_products
GROUP BY warehouseName, total_products.total
ORDER BY percentage_of_total DESC;






-- 7. Calculate the total number of products that each customer has purchased and rank them according to the greatest number of purchases.
WITH customer_order AS (
SELECT c.customerNumber, COUNT(o.orderNumber) AS cantidad_productos_comprados
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber
)
SELECT customerNumber, cantidad_productos_comprados,
	DENSE_RANK() OVER(ORDER BY cantidad_productos_comprados DESC) AS customer_rank
FROM customer_order;






-- 8. Find the most frequent customers, taking into account that they have made more than five purchase orders
SELECT c.customerNumber AS id,
	   c.customerName AS customer_most_frecuency, 
	   COUNT(o.orderNumber) AS quantity_order
FROM customers AS c
JOIN orders AS o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber, c.customerName
HAVING COUNT(o.orderNumber) > 5;





--  9. Which clients have spent more amount? On the assumption that they are required to be more than $250000.            
WITH sq1 AS(
	SELECT c.customerNumber AS id,
		   c.customerName AS nombre,
		   ROUND(SUM(p.amount),2) AS total
	FROM customers c
    JOIN payments p ON c.customerNumber = p.customerNumber
    GROUP BY c.customerNumber, c.customerName
)
SELECT id, nombre, total
FROM sq1
WHERE total > 250000;






 -- 10. Show the best-selling product lines with their quantities, for the two most frequent customers
 SELECT p.productLine,
		c.customerNumber AS customer,
	    SUM(od.quantityOrdered) AS total
FROM products p 
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON od.orderNumber = o.orderNumber 
JOIN customers c ON o.customerNumber = c.customerNumber
WHERE c.customerNumber IN ('124','141')
GROUP BY p.productLine, customer
ORDER BY productLine;






-- 11. Number of orders placed by the most frequent customers ('124' and '141')
SELECT c.customerNumber, 
	   COUNT(o.orderNumber) AS quantity_orders
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber
HAVING c.customerNumber IN ('124','141')
ORDER BY quantity_orders;





-- 12. Number of products purchased by the most frequent customers ('124' and '141')
SELECT  c.customerNumber AS id,
        SUM(od.quantityOrdered) AS quantity_products
FROM customers AS c
JOIN orders o ON c.customerNumber = o.customerNumber
JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE c.customerNumber IN ('124', '141')
GROUP BY c.customerNumber;





-- 13. Which product and how many units of that product have been bought by the most frequent customer ('124' and '141')? 
SELECT c.customerNumber, 
	   p.productName,
       SUM(od.quantityOrdered) AS total_prod
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN customers c ON o.customerNumber = c.customerNumber
JOIN products p ON od.productCode = p.productCode
GROUP BY c.customerNumber,p.productName
HAVING customerNumber IN ('124','141')
ORDER BY total_prod DESC;






-- 14. Obtain payments made by customers 124,141, along with the cumulative calculation of these payments for each customer over time
SELECT 
       p.paymentDate, 
       c.customerNumber AS id,
       p.amount,
	   ROUND(SUM(p.amount) OVER(PARTITION BY c.customerNumber ORDER BY p.paymentDate),2) AS cumulative_pay
FROM payments p
JOIN customers c ON p.customerNumber = c.customerNumber
GROUP BY id, p.paymentDate, p.amount
HAVING id IN ('124','141')
ORDER BY id;






-- 15. Identify those product lines that have more sales than 'planes'
SELECT p.productLine, 
	   COUNT(p.productLine) AS total_products
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN customers c ON o.customerNumber = c.customerNumber
GROUP BY p.productLine								
HAVING COUNT(p.productLine) >  (SELECT COUNT(c.customerNumber) AS customer_planes     -- The number of customers who have purchased airplanes is 96
								FROM customers AS c
								JOIN orders o ON c.customerNumber = o.customerNumber
								JOIN orderdetails od ON o.orderNumber = od.orderNumber 
								JOIN products p ON od.productCode = p.productCode
								WHERE p.productLine = 'Planes');
                                                    
                                                    
                                                    
							
                            
                            
                            
  
 -- 16. Categorize products into three popular categories ('High', 'Medium', 'Low') based on the total sold for each product
WITH orders AS (
SELECT p.productName, SUM(od.quantityOrdered) AS total
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY productName
ORDER BY total DESC
)
SELECT productName, total,
	CASE
		WHEN total < 300 THEN 'low'
        WHEN total BETWEEN 300 AND 350 THEN 'medium'
        ELSE 'high'
	END AS categorize_prod
FROM orders;
					                 
                             
                             
                             
                                     
                                     
                                     
-- 17. Compare actual selling prices with the prices the manufacturer recommends selling those products.
SELECT p.productCode,
       p.MSRP,
       od.priceEach
FROM products p 
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.MSRP, od.priceEach;







 -- 18. Ranking with the 10 most expensive orders
 SELECT * FROM 
			(SELECT od.orderNumber,
					c.customerNumber, 
					p.productName,
					(od.quantityOrdered * od.priceEach) AS total_sales,
					DENSE_RANK() OVER(ORDER BY quantityOrdered * priceEach DESC) AS DR_sales
			FROM products p JOIN orderdetails od ON p.productCode = od.productCode
            JOIN orders o ON od.orderNumber = o.orderNumber
            JOIN customers c ON o.customerNumber = c.customerNumber) AS sq1
HAVING DR_sales <= 10;
 
 
 -- Same result using a CTE (Common Table Expression)
WITH ranked_sales AS (
    SELECT od.orderNumber,
           c.customerNumber, 
           p.productName,
           (od.quantityOrdered * od.priceEach) AS total_sales,
           DENSE_RANK() OVER (ORDER BY (od.quantityOrdered * od.priceEach) DESC) AS DR_sales
    FROM products p 
    JOIN orderdetails od ON p.productCode = od.productCode
    JOIN orders o ON od.orderNumber = o.orderNumber
    JOIN customers c ON o.customerNumber = c.customerNumber
)
SELECT *
FROM ranked_sales
WHERE DR_sales <= 10
ORDER BY total_sales DESC;






 -- 19. Search for those customers who have purchased at least one product that belongs to all product lines
 SELECT c.customerNumber, COUNT(DISTINCT p.productLine) AS productLine
 FROM customers c
 JOIN orders o ON c.customerNumber = o.customerNumber
 JOIN orderdetails od ON o.orderNumber = od.orderNumber
 JOIN products p ON od.productCode = p.productCode
 GROUP BY c.customerNumber
 HAVING productLine = (SELECT COUNT(DISTINCT productLine) FROM productLines);
 
 
 
 
 
 
 
 -- 20. Calculate profit margin:
SELECT 
        p.productName,
        p.buyPrice,
        od.priceEach,
	   ROUND(priceEach - buyPrice,2) AS gross_margin,
       ROUND((priceEach - buyPrice) / buyPrice,2) * 100 AS profit_margin_percentage,
CASE
       WHEN (ROUND((priceEach - buyPrice) / buyPrice,2) * 100) >= 30 THEN 'YES'
       WHEN (ROUND((priceEach - buyPrice) / buyPrice,2) * 100) < 30 THEN 'NO'
END AS margin_classification       
FROM products p 
JOIN orderdetails od ON p.productCode = od.productCode;