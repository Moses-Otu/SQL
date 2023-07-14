
-- Percentage of total sales for each country.


SELECT
  Country,
  CONCAT('N ', FORMAT(ROUND(SUM(Quantity * UnitPrice), 2), 'N')) AS TotalAmount,
  CONCAT(ROUND((SUM(Quantity * UnitPrice)
  / (SELECT
    SUM(Quantity * UnitPrice)
  FROM testdata)
  ) * 100, 2), '%') AS PercentageOfTotal
FROM testdata
GROUP BY Country
ORDER BY PercentageOfTotal DESC;


-- Sales Trend per Month


WITH CTE
AS (SELECT
  DATEPART(YEAR, InvoiceDate) AS Year,
  LEFT(DATENAME(MONTH, InvoiceDate), 3) AS Month,
  ROW_NUMBER() OVER (ORDER BY DATEPART(YEAR, InvoiceDate), LEFT(DATENAME(MONTH, InvoiceDate), 3)) AS lol,
  ROUND(SUM(Quantity * UnitPrice), 2) AS totalSales
FROM testdata
GROUP BY DATEPART(YEAR, InvoiceDate),
         LEFT(DATENAME(MONTH, InvoiceDate), 3))
SELECT
  concat(Month, ' ', Year) AS month,
  totalSales
FROM CTE
ORDER BY lol;


-- Create a stored procedure for the trend data


CREATE PROCEDURE SalesTrend
AS
BEGIN
  WITH CTE
  AS (SELECT
    DATEPART(YEAR, InvoiceDate) AS Year,
    LEFT(DATENAME(MONTH, InvoiceDate), 3) AS Month,
    ROW_NUMBER() OVER (ORDER BY DATEPART(YEAR, InvoiceDate), LEFT(DATENAME(MONTH, InvoiceDate), 3)) AS row_order,
    ROUND(SUM(Quantity * UnitPrice), 0) AS totalSales
  FROM testdata
  GROUP BY DATEPART(YEAR, InvoiceDate),
           LEFT(DATENAME(MONTH, InvoiceDate), 3))
  SELECT
    concat(Month, ' ', Year) AS month,
    totalSales
  FROM CTE
  ORDER BY row_order;
END

  EXEC SalesTrend
  
  

-- What Time During the Day Do Customers Make the Most Purchases?


  WITH CTE
  AS (SELECT
    DATEPART(YEAR, InvoiceDate) AS Year,
    DATEPART(MONTH, InvoiceDate) AS Month,
    DATEPART(HOUR, InvoiceDate) AS Hour,
    COUNT(DISTINCT InvoiceNo) AS No_of_order
  FROM testdata
  WHERE DATEPART(MONTH, InvoiceDate) = 12

  GROUP BY DATEPART(YEAR, InvoiceDate),
           DATEPART(MONTH, InvoiceDate),
           DATEPART(HOUR, InvoiceDate))

  SELECT
    CONCAT(Year, '-', Month) AS month,
    Hour,
    No_of_order
  FROM CTE
  ORDER BY month, Hour
  
-- pivot


  WITH CTE
  AS (SELECT
    DATEPART(YEAR, InvoiceDate) AS Year,
    DATEPART(MONTH, InvoiceDate) AS Month,
    DATEPART(HOUR, InvoiceDate) AS Hour,
    COUNT(DISTINCT InvoiceNo) AS No_of_order
  FROM testdata
  WHERE DATEPART(MONTH, InvoiceDate) IN (10, 11, 12)
  GROUP BY DATEPART(YEAR, InvoiceDate),
           DATEPART(MONTH, InvoiceDate),
           DATEPART(HOUR, InvoiceDate))

  SELECT
    CONCAT(Year, '-', Month) AS Month,
    [7],
    [8],
    [9],
    [10],
    [11],
    [12],
    [13],
    [14],
    [15],
    [16],
    [17],
    [18],
    [19],
    [20]
  FROM CTE
  PIVOT
  (
  SUM(No_of_order)
  FOR Hour IN ([7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20])
  ) AS PivotTable
  ORDER BY Month;
  

  -- When were the largest orders made?
  
  
  WITH ord
  AS (SELECT
    InvoiceNo,
    MAX(CONVERT(date, InvoiceDate)) AS date,
    ROUND(SUM(Quantity * UnitPrice), 0) AS sales
  FROM testdata
  GROUP BY InvoiceNo)

  SELECT
    InvoiceNo,
    FORMAT(date, 'dd-MMM-yyyy') AS [date],
    CONCAT('N ', FORMAT(sales, 'N', 'en-US')) AS total_sales
  FROM ord
  ORDER BY sales DESC
  
  

  --Which was the best selling product in each country?
  
  
 WITH prod
  AS (SELECT
    Country,
    Description,
    SUM(Quantity * UnitPrice) AS total_sales,
    SUM(SUM(Quantity * UnitPrice)) OVER (PARTITION BY Country) AS sales_per_country,
    RANK() OVER (PARTITION BY Country ORDER BY SUM(Quantity * UnitPrice) DESC) AS rank
  FROM testdata
  GROUP BY Country,
           Description)

  SELECT
    Country,
    Description,
    CONCAT('N ', FORMAT(total_sales, 'N', 'en-US')) AS total_sales,
    CONCAT('N ', FORMAT(sales_per_country, 'N', 'en-US')) AS country_sales,
    concat(ROUND(total_sales / sales_per_country * 100, 2), '%') AS perc
  FROM prod
  WHERE rank = 1
  GROUP BY Country,
           Description,
           total_sales,
           sales_per_country;
		   
		   


--Which Customers Contributed the Most to Total Sales?


  WITH SD
  AS (SELECT
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS number_of_orders,
    ROUND(SUM(Quantity * UnitPrice), 0) AS sales
  FROM testdata
  WHERE CustomerID IS NOT NULL
  GROUP BY CustomerID)

  SELECT
    CustomerID,
    number_of_orders,
    CONCAT('N ', FORMAT(sales, 'N', 'en-US')) AS total_sales,
    CONCAT(ROUND(sales / (SELECT
      SUM(Quantity * UnitPrice)
    FROM testdata)
    * 100, 2), '%') AS perc
  FROM SD
  ORDER BY perc DESC
