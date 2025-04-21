CREATE TABLE ModelNames (
    ModelName VARCHAR(20) NOT NULL PRIMARY KEY
)

INSERT INTO ModelNames (ModelName)
VALUES
    ('Blade C18'),
    ('Blade L-C36'),
    ('Shelf C18'),
    ('Fury C18'),
    ('Electro C18'),
    ('Loft C36'),
    ('Cuby C36'),
    ('Cuby II C36'),
    ('C36'),
    ('Fury L-B36'),
    ('Combat L-C36'),
    ('Electro L-C36'),
    ('Elevate L-B36'),
    ('Loft L-C36'),
    ('Cuby L-C36'),
    ('Cuby II L-C36'),
    ('Modern L-B36'),
    ('undefined L-B36')


CREATE TABLE LegColors(
LegColor Varchar(20) NOT NULL PRIMARY KEY
)



INSERT INTO LegColors (LegColor)
VALUES
    ('Black'),
    ('White')


CREATE TABLE Colors (
    Color VARCHAR(30) NOT NULL PRIMARY KEY
)

INSERT INTO Colors (Color)
VALUES
    ('BLACK'),
    ('TRAVITA OAK'),
    ('Dark CONCRETE'),
    ('CALIFORNIA NUT'),
    ('RETRO'),
    ('GRAPHITE'),
    ('CRAFT GOLD OAK'),
    ('MILLENNIUM CONCRETE'),
    ('AMERICAN OAK'),
    ('SONOMA OAK'),
    ('MAPLE'),
    ('LIGHT GRAY'),
    ('VERONA ASH'),
    ('WHITE')



CREATE TABLE Credit_Cards (
    Number VARCHAR(16) PRIMARY KEY NOT NULL,
    CVV CHAR(3) NOT NULL,
    Exp_Date VARCHAR(5) NOT NULL, -- שומר את התאריך בפורמט MM/YY
    Owner_Name VARCHAR(100) NOT NULL,
    CONSTRAINT chk_card_number_length CHECK (LEN(Number) BETWEEN 15 AND 16), 
    CONSTRAINT chk_cvv_length CHECK (LEN(CVV) = 3),
    CONSTRAINT chk_exp_date_format CHECK (Exp_Date LIKE '[0-1][0-9]/[0-9][0-9]'), -- בודק את הפורמט MM/YY
);



CREATE TABLE Models (
ModelName VARCHAR(20) NOT NULL,
CONSTRAINT PK_MODELS PRIMARY KEY (ModelName),
CONSTRAINT FK_ModelName FOREIGN KEY (ModelName)
REFERENCES ModelNames (ModelName)
)

CREATE TABLE Customers (
    Email VARCHAR(50) NOT NULL PRIMARY KEY,
    [Password] VARCHAR(12) NULL,
    Phone VARCHAR(20) NULL,
    [Customer Name] VARCHAR(30) NULL,
    CONSTRAINT CHK_Email CHECK (Email LIKE '%@%._%'),
    CONSTRAINT chk_phone_digits CHECK (Phone IS NULL OR Phone NOT LIKE '%[^0-9]%'),
    CONSTRAINT CHK_Password_Length CHECK (
        LEN(COALESCE([Password], '')) = 0 OR 
        (LEN([Password]) BETWEEN 8 AND 16)
    )
)




CREATE TABLE Carts (
    CartID INT NOT NULL,
    CartDT DATETIME NOT NULL,
    Email VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Carts PRIMARY KEY(CartID),
    CONSTRAINT FK_Customers FOREIGN KEY (Email) REFERENCES Customers(Email)
);




CREATE TABLE Orders (
OrderID Int NOT NULL
CONSTRAINT PK_Orders PRIMARY KEY(OrderID),
OrderDate Date NOT NULL,
AddressStreet Varchar(20) NOT NULL,
AddressNumber Int NOT NULL,
AddressZIPCode Int NOT NULL,
AddressCity Varchar(20) NOT NULL,
AddressCountry Varchar(20) NOT NULL,
CreditCard VarChar(16) NOT NULL,
CartID Int NOT NULL,
CONSTRAINT FK_CreditCards
FOREIGN KEY (CreditCard)
REFERENCES Credit_Cards(Number),
CONSTRAINT FK_Carts_Orders
FOREIGN KEY (CartID)
REFERENCES Carts(CartID)
)




CREATE TABLE Reviews (
 ModelName Varchar(20),
 DT DATETIME NOT NULL,
 Rate SmallINT,
 Nickname VARCHAR(20) NOT NULL,
 [Text] VarChar(500) NULL,
 Email VARCHAR(50) NOT NULL,
 PRIMARY KEY (ModelName, DT),
 CONSTRAINT FK_Models_Reviews
 FOREIGN KEY (ModelName)
 REFERENCES Models(ModelName),
 CONSTRAINT FK_CustomersEmail
 FOREIGN KEY (Email)
 REFERENCES Customers(Email)
)

ALTER TABLE Reviews
ADD CONSTRAINT CK_Reviews_Rate
CHECK (Rate BETWEEN 1 AND 5)


CREATE TABLE BasicDesigns(
 ModelName VARCHAR(20) NOT NULL,
 SessionID Int NOT NULL,
 [Length] SmallInt NOT NULL,
 Height SmallInt NOT NULL,
 Color Varchar(30) NOT NULL,
 Price SmallMoney NULL
 PRIMARY KEY (ModelName, SessionID)
 CONSTRAINT FK_Models_Design
 FOREIGN KEY (ModelName)
 REFERENCES Models(ModelName),
 CONSTRAINT FK_Color 
 FOREIGN KEY (Color)
 REFERENCES Colors (Color)
)

ALTER TABLE BasicDesigns
ADD CONSTRAINT chk_dimensions_positive
CHECK ([Length] BETWEEN 900 AND 1500 AND Height BETWEEN 500 AND 800)

CREATE TABLE DeskDesigns (
 ModelName Varchar(20) NOT NULL,
 SessionID INT NOT NULL,
 LegColor VARCHAR(20) NULL,
 InductiveCharger Bit NULL ,
 PowerStrip Bit NULL,
 HeadphoneAndCupholder Bit NULL,
 KeyboardDrawer Bit NULL,
 AllIN1 Bit NULL,
 PRIMARY KEY (ModelName, SessionID),
 CONSTRAINT FK_BasicDesigns 
 FOREIGN KEY (ModelName, SessionID)
 REFERENCES BasicDesigns(ModelName, SessionID),
 CONSTRAINT FK_LegColor 
 FOREIGN KEY (LegColor)
 REFERENCES LegColors (LegColor)
 )

CREATE TABLE AddedTo (
 ModelName Varchar(20) NOT NULL,
 SessionID INT NOT NULL,
 CartID INT NOT NULL,
 Quantity SmallINT NOT NULL DEFAULT 1,
 PRIMARY KEY (ModelName, SessionID, CartID),
 CONSTRAINT FK_BasicDesigns2 
 FOREIGN KEY (ModelName, SessionID)
 REFERENCES BasicDesigns(ModelName, SessionID),
 CONSTRAINT FK_Carts_AddedTo 
 FOREIGN KEY(CartID)
 REFERENCES Carts(CartID)
)

ALTER TABLE AddedTo
ADD CONSTRAINT Quantity
CHECK (Quantity > 0)

DROP TABLE AddedTo;
DROP TABLE DeskDesigns;
DROP TABLE BasicDesigns;
DROP TABLE Reviews;
DROP TABLE Orders;
DROP TABLE Carts;


DROP TABLE Customers;
DROP TABLE Models;
DROP TABLE Credit_Cards;


DROP TABLE Colors;
DROP TABLE LegColors;
DROP TABLE ModelNames;



---queries

-- ******* REGULAR QUERIES *******

-- The query retrieves the top 10 customers along with their email 
-- addresses and total revenue generated in 2024, sorted by revenue in descending order.

SELECT TOP 10
    CU.[Customer Name] AS [Customer],
    CU.Email AS [Email],
    SUM(AT.Quantity * BD.Price) AS [TotalRevenue]
FROM AddedTo AT
INNER JOIN Carts CT
    ON AT.CartID = CT.CartID
INNER JOIN Customers CU
    ON CT.Email = CU.Email
INNER JOIN BasicDesigns BD
    ON AT.ModelName = BD.ModelName AND AT.SessionID = BD.SessionID
INNER JOIN Orders O
    ON CT.CartID = O.CartID
WHERE O.OrderDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY CU.[Customer Name], CU.Email
ORDER BY SUM(AT.Quantity * BD.Price) DESC



-- The query retrieves the most popular colors for tables priced above 100, excluding those with less than 10 total purchases,
-- and ranks them by the number of orders.

SELECT 
    BD.Color AS [Most Wanted Color],
    COUNT(*) AS [Total Orders],
    SUM(AT.Quantity) AS [Total Model Purchases]
FROM AddedTo AT
INNER JOIN BasicDesigns BD
    ON AT.ModelName = BD.ModelName AND AT.SessionID = BD.SessionID
INNER JOIN DeskDesigns DD
    ON BD.ModelName = DD.ModelName AND BD.SessionID = DD.SessionID
INNER JOIN Orders O
    ON AT.CartID = O.CartID
WHERE BD.Price > 200
GROUP BY BD.Color
HAVING SUM(AT.Quantity) >= 20
ORDER BY COUNT(*) DESC;



-- ******* NESTED QUERIES *******

-- The query retrieves the top 5 most-ordered models (by total quantity sold) that have an average review rating greater than 2.5,
-- sorted by total quantity in descending order.

SELECT TOP 5
    AT.ModelName,
    SUM(AT.Quantity) AS [Total Quantity]
FROM AddedTo AT
INNER JOIN Orders O
    ON AT.CartID = O.CartID
WHERE AT.ModelName IN (
    SELECT R.ModelName
    FROM Reviews R
    GROUP BY R.ModelName
    HAVING AVG(R.Rate) > 2.5 
)
GROUP BY AT.ModelName
ORDER BY [Total Quantity] DESC;


-- The query retrieves countries with more than 10 total orders, where the average order price exceeds the global average,
-- and sorts the results by average price in descending order.

SELECT 
    Orders.AddressCountry AS Country,
    AVG(BasicDesigns.Price * Addedto.Quantity) AS [Average Order Price],
    COUNT(Orders.OrderID) AS [Total Orders]
FROM Orders
JOIN Addedto ON Orders.CartID = Addedto.CartID
JOIN BasicDesigns ON Addedto.ModelName = BasicDesigns.ModelName
                   AND Addedto.SessionID = BasicDesigns.SessionID
WHERE Orders.AddressCountry IN (
    SELECT Orders.AddressCountry
    FROM Orders
    GROUP BY Orders.AddressCountry
    HAVING COUNT(Orders.OrderID) > 10
)
GROUP BY Orders.AddressCountry
HAVING AVG(BasicDesigns.Price * Addedto.Quantity) > (
    SELECT AVG(BD.Price * AT.Quantity)
    FROM Orders O
    JOIN Addedto AT ON O.CartID = AT.CartID
    JOIN BasicDesigns BD ON AT.ModelName = BD.ModelName
                          AND AT.SessionID = BD.SessionID
)
ORDER BY [Average Order Price] DESC;


-- ******* WINDOW QUERIES *******

-- This query calculates the total revenue, average order value, and the revenue rank within
-- each country for customers who have spent more than 500 on valid orders,
-- where revenue is calculated as the sum of the product of item price (BD.Price) and quantity 
-- (A.Quantity) from valid carts linked to orders.

SELECT
    C.[Customer Name], 
    C.Email,
    O.AddressCountry as Country,
    SUM(BD.Price * A.Quantity) AS [Total Revenue],
    AVG(BD.Price * A.Quantity) AS [Average Order Value],
    RANK() OVER (PARTITION BY O.AddressCountry ORDER BY SUM(BD.Price * A.Quantity) DESC) AS [Revenue Rank Within Country]
FROM 
    Customers C
JOIN Carts CA ON C.Email = CA.Email
JOIN Addedto A ON CA.CartID = A.CartID
JOIN BasicDesigns BD ON A.ModelName = BD.ModelName 
                     AND A.SessionID = BD.SessionID
JOIN Orders O ON CA.CartID = O.CartID
GROUP BY 
    C.Email,
    C.[Customer Name],
    O.AddressCountry
HAVING 
    SUM(BD.Price * A.Quantity) > 1000
ORDER BY 
    O.AddressCountry, [Total Revenue] DESC;


-- This query calculates the total revenue from all valid orders by summing the product of item price
-- and quantity for each item in the orders.

SELECT
    Year,
    Month_Quantile,
    SUM(Total_Revenue) AS Revenue,
    SUM(Total_Revenue) /
        FIRST_VALUE(SUM(Total_Revenue)) OVER (ORDER BY Year, Month_Quantile) - 1 AS Growth_Since_Beginning,
    SUM(Total_Revenue) /
        LAG(SUM(Total_Revenue)) OVER (ORDER BY Year, Month_Quantile) - 1 AS Growth_From_Previous_Quantile,
    SUM(Total_Revenue) /
        LAG(SUM(Total_Revenue), 2) OVER (ORDER BY Year, Month_Quantile) - 1 AS Growth_From_Two_Quantiles_Ago
FROM (
    SELECT
        YEAR(O.OrderDate) AS Year,
        MONTH(O.OrderDate) AS Month,
        NTILE(4) OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY MONTH(O.OrderDate)) AS Month_Quantile,
        SUM(BD.Price * A.Quantity) AS Total_Revenue
    FROM 
        Orders O
    JOIN Addedto A ON O.CartID = A.CartID 
    JOIN BasicDesigns BD ON A.ModelName = BD.ModelName AND A.SessionID = BD.SessionID 
    GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
) AS Monthly_Revenue
GROUP BY Year, Month_Quantile
ORDER BY Year, Month_Quantile;



-- This query calculates total monthly revenue, divides the year into quarters,
--and computes the month-over-month revenue growth as a percentage (including a % sign)
-- for each month in the dataset.

SELECT
    YEAR(O.OrderDate) AS Year,
    MONTH(O.OrderDate) AS Month,
    NTILE(4) OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY MONTH(O.OrderDate)) AS Quarter, -- Split into quarters
    SUM(BD.Price * A.Quantity) AS TotalRevenue, -- Total revenue for the month
    CASE 
        WHEN LAG(SUM(BD.Price * A.Quantity)) OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY MONTH(O.OrderDate)) IS NULL THEN '0.00%'
        ELSE 
            CAST(ROUND(
                (SUM(BD.Price * A.Quantity) 
                / LAG(SUM(BD.Price * A.Quantity)) OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY MONTH(O.OrderDate)) - 1) * 100, 2
            ) AS VARCHAR) + '%'
    END AS MonthlyGrowthPercentage -- Monthly growth as a percentage with a % sign
FROM 
    Orders O
JOIN AddedTo A ON O.CartID = A.CartID
JOIN BasicDesigns BD ON A.ModelName = BD.ModelName AND A.SessionID = BD.SessionID
GROUP BY YEAR(O.OrderDate), MONTH(O.OrderDate)
ORDER BY Year, Quarter, Month;


-- his query calculates each model's total revenue, assigns it to a current revenue segment,
-- and adds the segment from the previous year for trend analysis.

SELECT
    BD.ModelName AS ModelName,
    YEAR(O.OrderDate) AS Year,
    SUM(BD.Price * A.Quantity) AS Revenue, -- Total revenue for the model
    ROUND(PERCENT_RANK() OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY SUM(BD.Price * A.Quantity) ASC), 2) AS PercentileRank, -- Rounded Revenue percentile rank
    CASE 
        WHEN ROUND(PERCENT_RANK() OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY SUM(BD.Price * A.Quantity) ASC), 2) <= 0.33 THEN 'Low-End'
        WHEN ROUND(PERCENT_RANK() OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY SUM(BD.Price * A.Quantity) ASC), 2) <= 0.66 THEN 'Mid-Range'
        WHEN ROUND(PERCENT_RANK() OVER (PARTITION BY YEAR(O.OrderDate) ORDER BY SUM(BD.Price * A.Quantity) ASC), 2) > 0.95 THEN 'BEST SELLING'
        ELSE 'High-End'
    END AS RevenueSegment -- Segment based on revenue percentiles
FROM 
    Orders O
JOIN Carts C ON O.CartID = C.CartID
JOIN AddedTo A ON C.CartID = A.CartID
JOIN BasicDesigns BD ON A.ModelName = BD.ModelName AND A.SessionID = BD.SessionID
GROUP BY BD.ModelName, YEAR(O.OrderDate)
ORDER BY Year, PercentileRank;



-- ******* query using CTE *******

-- The query identifies models with total orders above the 75th percentile,
-- calculates the count and average price of each color and leg color combination
-- for those models, and ranks the combinations by model and their popularity.

WITH
ModelOrders AS (
    -- Subquery 1: Calculate the total number of orders for each model
    SELECT
        A.ModelName,
        COUNT(DISTINCT O.OrderID) AS TotalOrders
    FROM AddedTo A
    JOIN Orders O ON A.CartID = O.CartID
    GROUP BY A.ModelName
),
MedianAndAverage AS (
    -- Subquery 2: Calculate the average and median of TotalOrders using window functions
    SELECT
        DISTINCT
        AVG(TotalOrders) OVER () AS AvgOrders, -- Average over all TotalOrders
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY TotalOrders) OVER () AS MedianOrders
    FROM ModelOrders
),
ValidModels AS (
    -- Subquery 3: Filter models that exceed the median or average
    SELECT 
        MO.ModelName
    FROM ModelOrders MO
    CROSS JOIN MedianAndAverage MA
    WHERE MO.TotalOrders > MA.MedianOrders 
),
CombinationDetails AS (
    -- Subquery 4: Calculate total sales and average price for each combination (Color, LegColor) for valid models
    SELECT
        A.ModelName,
        BD.Color,
        DD.LegColor,
        COUNT(*) AS CombinationCount,
        AVG(BD.Price) AS AveragePrice -- Calculate average price for the combination
    FROM AddedTo A
    JOIN BasicDesigns BD ON A.ModelName = BD.ModelName AND A.SessionID = BD.SessionID
    JOIN DeskDesigns DD ON BD.ModelName = DD.ModelName AND BD.SessionID = DD.SessionID
    WHERE A.ModelName IN (SELECT ModelName FROM ValidModels) -- Include only valid models
    GROUP BY A.ModelName, BD.Color, DD.LegColor
)
-- Final query: Retrieve combination details along with average price
SELECT
    CD.ModelName,
    CD.Color,
    CD.LegColor,
    CD.CombinationCount,
    CD.AveragePrice
FROM CombinationDetails CD
ORDER BY CD.ModelName, CD.CombinationCount DESC;



-- ******* query using VIEW *******

CREATE VIEW CustomerBehavior AS
SELECT 
    CU.Email AS CustomerEmail,
    SUM(BD.Price * AT.Quantity) AS TotalSpent, 
    AVG(BD.Price * AT.Quantity) AS AvgOrderValue, 
    SUM(AT.Quantity) AS TotalQuantity, 
    COUNT(DISTINCT CT.CartID) AS TotalOrders, 
    MIN(O.OrderDate) AS FirstPurchaseDate, 
    MAX(O.OrderDate) AS LastPurchaseDate, 
    (SELECT TOP 1 BD.Color 
     FROM AddedTo AT2
     JOIN BasicDesigns BD ON AT2.ModelName = BD.ModelName AND AT2.SessionID = BD.SessionID
     JOIN Carts CT2 ON AT2.CartID = CT2.CartID
     WHERE CT2.Email = CU.Email 
     GROUP BY BD.Color
     ORDER BY COUNT(*) DESC) AS PreferredColor, 
    CASE 
        WHEN DATEDIFF(DAY, MAX(O.OrderDate), GETDATE()) > 60 THEN 'High' 
        ELSE 'Low'
    END AS ChurnRisk -- Indicates the likelihood of churn based on inactivity
FROM Customers CU
JOIN Carts CT ON CU.Email = CT.Email
JOIN AddedTo AT ON CT.CartID = AT.CartID
JOIN BasicDesigns BD ON AT.ModelName = BD.ModelName AND AT.SessionID = BD.SessionID
JOIN Orders O ON CT.CartID = O.CartID
GROUP BY CU.Email;

SELECT * FROM CustomerBehavior


-- ******* query using Custom Functions *******

-- Table-Valued Function: 

CREATE FUNCTION dbo.GetFrequentBuyers (@MaxDaysBetweenPurchases INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        CU.Email AS CustomerEmail,
        CU.[Customer Name],
        COUNT(DISTINCT O.OrderDate) AS TotalPurchaseDays,
        MIN(O.OrderDate) AS FirstPurchaseDate,
        MAX(O.OrderDate) AS LastPurchaseDate,
        CASE 
            WHEN COUNT(DISTINCT O.OrderDate) <= 1 THEN NULL -- Undefined if only 1 or no purchases
            ELSE CAST(
                CAST(DATEDIFF(DAY, MIN(O.OrderDate), MAX(O.OrderDate)) AS DECIMAL) / 
                NULLIF((COUNT(DISTINCT O.OrderDate) - 1), 0) 
                AS DECIMAL(18, 2)
            )
        END AS AvgDaysBetweenPurchases
    FROM Customers CU
    JOIN Carts CT ON CU.Email = CT.Email
    JOIN Orders O ON CT.CartID = O.CartID
    GROUP BY CU.Email, CU.[Customer Name]
    HAVING 
        COUNT(DISTINCT O.OrderDate) > 1 AND -- Ensure at least two purchases to avoid division by zero
        CASE 
            WHEN COUNT(DISTINCT O.OrderDate) <= 1 THEN NULL
            ELSE CAST(
                CAST(DATEDIFF(DAY, MIN(O.OrderDate), MAX(O.OrderDate)) AS DECIMAL) / 
                NULLIF((COUNT(DISTINCT O.OrderDate) - 1), 0) 
                AS DECIMAL(18, 2)
            )
        END < @MaxDaysBetweenPurchases
);


SELECT * FROM dbo.GetFrequentBuyers(30);


-- Scalar-Valued Function: 

CREATE FUNCTION dbo.GetCartConversionRate (@Year INT)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @TotalCarts INT;
    DECLARE @ConvertedCarts INT;
    DECLARE @ConversionRate DECIMAL(5, 2);

    -- Count the total carts created in the specified year
    SELECT @TotalCarts = COUNT(*)
    FROM Carts
    WHERE YEAR(CartDT) = @Year;

    -- Count the carts that were converted into orders
    SELECT @ConvertedCarts = COUNT(DISTINCT O.CartID)
    FROM Carts C
    JOIN Orders O ON C.CartID = O.CartID
    WHERE YEAR(C.CartDT) = @Year;

    -- Calculate the conversion rate
    IF @TotalCarts = 0
        SET @ConversionRate = 0; -- Avoid divide-by-zero
    ELSE
        SET @ConversionRate = CAST(@ConvertedCarts AS DECIMAL(5, 2)) * 100 / @TotalCarts;

    RETURN @ConversionRate;
END;


SELECT dbo.GetCartConversionRate(2025) AS [Cart Conversion Rate];




CREATE VIEW OrdersByCountry AS
SELECT 
    AddressCountry AS Country, 
    COUNT(OrderID) AS TotalOrders
FROM 
    Orders
GROUP BY 
    AddressCountry;





CREATE PROCEDURE ApplyBonusToHighSpenders
    @ThresholdAmount MONEY -- Input: Minimum total spent to qualify for the bonus
AS
BEGIN
    -- Temporary table to store customers eligible for the bonus
    CREATE TABLE #EligibleCustomers (
        Email VARCHAR(50),
        [Customer Name] VARCHAR(100),
        TotalSpent MONEY,
        GiftCardAmount INT
    );

    -- Calculate the total amount spent by each customer in the last 6 months and determine the gift card amount
    INSERT INTO #EligibleCustomers (Email, [Customer Name], TotalSpent, GiftCardAmount)
    SELECT 
        C.Email,
        C.[Customer Name],
        SUM(B.Price) AS TotalSpent,  -- Calculate total spent
        CASE 
            WHEN SUM(B.Price) > @ThresholdAmount THEN 
                CAST(
                    ROUND(
                        CASE 
                            -- Calculate the percentage using the logarithmic function
                            WHEN 10 + LOG(1 + (SUM(B.Price) - @ThresholdAmount) / @ThresholdAmount) * 17 > 35 
                            THEN 35
                            WHEN 10 + LOG(1 + (SUM(B.Price) - @ThresholdAmount) / @ThresholdAmount) * 17 < 10
                            THEN 10
                            ELSE 10 + LOG(1 + (SUM(B.Price) - @ThresholdAmount) / @ThresholdAmount) * 17
                        END * 10, -- Convert the percentage into a gift card amount
                        0 -- Round to the nearest whole number
                    ) AS INT
                )
            ELSE 0
        END AS GiftCardAmount
    FROM 
        Carts CA
        INNER JOIN Customers C ON CA.Email = C.Email
        INNER JOIN Orders O ON CA.CartID = O.CartID  -- Include only completed orders
        INNER JOIN AddedTo A ON CA.CartID = A.CartID
        INNER JOIN BasicDesigns B ON A.ModelName = B.ModelName AND A.SessionID = B.SessionID
    WHERE 
        O.OrderDate >= DATEADD(MONTH, -6, GETDATE()) -- Only include orders from the last 6 months
    GROUP BY C.Email, C.[Customer Name];

    -- Display the customers eligible for the bonus along with their gift card amount
    SELECT 
        EC.Email AS Customer_Email,
        EC.[Customer Name] AS Customer_Name,
        EC.TotalSpent AS Total_Spent,
        EC.GiftCardAmount AS Gift_Card_Amount
    FROM #EligibleCustomers EC;

    -- Drop the temporary table
    DROP TABLE #EligibleCustomers;
END;

-- Execute the procedure
EXEC ApplyBonusToHighSpenders @ThresholdAmount = 400;




--optimized for second nested query 
WITH CountryOrderStats AS (
    SELECT 
        Orders.AddressCountry AS Country,
        AVG(BasicDesigns.Price * Addedto.Quantity) AS AvgOrderPrice,
        COUNT(Orders.OrderID) AS TotalOrders
    FROM Orders
    JOIN Addedto ON Orders.CartID = Addedto.CartID
    JOIN BasicDesigns ON Addedto.ModelName = BasicDesigns.ModelName
                       AND Addedto.SessionID = BasicDesigns.SessionID
    GROUP BY Orders.AddressCountry
    HAVING COUNT(Orders.OrderID) > 10
),
GlobalAvg AS (
    SELECT AVG(BD.Price * AT.Quantity) AS GlobalAvgPrice
    FROM Orders O
    JOIN Addedto AT ON O.CartID = AT.CartID
    JOIN BasicDesigns BD ON AT.ModelName = BD.ModelName
                          AND AT.SessionID = BD.SessionID
)
SELECT 
    COS.Country,
    COS.AvgOrderPrice AS [Average Order Price],
    COS.TotalOrders AS [Total Orders]
FROM CountryOrderStats COS
CROSS JOIN GlobalAvg GA
WHERE COS.AvgOrderPrice > GA.GlobalAvgPrice
ORDER BY COS.AvgOrderPrice DESC;
-----optimized for fourth window query 
-- Create Indexes for Optimization
CREATE INDEX idx_orders_orderdate_cartid
ON Orders (OrderDate, CartID);

CREATE INDEX idx_carts_cartid
ON Carts (CartID);

CREATE INDEX idx_addedto_cartid_modelname_sessionid_quantity
ON AddedTo (CartID, ModelName, SessionID, Quantity);

CREATE INDEX idx_basicdesigns_modelname_sessionid_price
ON BasicDesigns (ModelName, SessionID, Price);

-- Optimized Query
WITH RevenueData AS (
    SELECT
        BD.ModelName AS ModelName,
        YEAR(O.OrderDate) AS Year,
        SUM(BD.Price * A.Quantity) AS Revenue -- Total revenue for the model
    FROM 
        Orders O
    JOIN Carts C ON O.CartID = C.CartID
    JOIN AddedTo A ON C.CartID = A.CartID
    JOIN BasicDesigns BD ON A.ModelName = BD.ModelName AND A.SessionID = BD.SessionID
    GROUP BY BD.ModelName, YEAR(O.OrderDate)
),
RankedRevenue AS (
    SELECT
        ModelName,
        Year,
        Revenue,
        PERCENT_RANK() OVER (PARTITION BY Year ORDER BY Revenue ASC) AS PercentileRank -- Percentile rank calculation
    FROM 
        RevenueData
)
SELECT
    ModelName,
    Year,
    Revenue,
    ROUND(PercentileRank, 2) AS PercentileRank, -- Rounded Revenue percentile rank
    CASE 
        WHEN ROUND(PercentileRank, 2) <= 0.33 THEN 'Low-End'
        WHEN ROUND(PercentileRank, 2) <= 0.66 THEN 'Mid-Range'
        WHEN ROUND(PercentileRank, 2) > 0.95 THEN 'BEST SELLING'
        ELSE 'High-End'
    END AS RevenueSegment -- Segment based on revenue percentiles
FROM
    RankedRevenue
ORDER BY Year, PercentileRank;
---triger
--Build trigger updating avarege rate of each model
--Add colunm to model table
ALTER TABLE Models
ADD AverageRate DECIMAL(4, 2) NULL; --average is decimal
GO
--Create trigger
CREATE TRIGGER tr_UpdateModelsAvgRate
ON Reviews
AFTER INSERT, UPDATE, DELETE
AS
BEGIN

    UPDATE M
    SET M.AverageRate = (
        SELECT AVG(CAST(R.Rate AS DECIMAL(10, 2)))
        FROM Reviews R 
        WHERE R.ModelName = M.ModelName
    )
    /* 
       נשים WHERE לפי כל הדגמים שהשתנו, כדי לא לעדכן סתם את כל הטבלה,
       אלא רק את הדגמים שהתווספו/עודכנו/נמחקו.
    */
    FROM Models M
    WHERE M.ModelName IN 
    (
        SELECT ModelName FROM Inserted  -- רשומות שנוספו או עודכנו
        UNION
        SELECT ModelName FROM Deleted   -- רשומות שנמחקו או שהשתנו לפני העדכון
    );
END;
GO

ALTER TABLE Reviews
ADD OfferSent BIT DEFAULT 0;

SELECT ModelName, Rate, Nickname, OfferSent
FROM Reviews
WHERE Rate < 3;


UPDATE Reviews
SET OfferSent = 1
WHERE Rate < 3
  AND ModelName IN (
      SELECT ModelName
      FROM Models
      WHERE AverageRate < 4
  );

  SELECT ModelName, Rate, Nickname, OfferSent
FROM Reviews
WHERE Rate < 3;





CREATE VIEW PowerBI_View AS
WITH OrderMetrics AS (
    SELECT
        o.OrderID,
        SUM(bd.Price * at.Quantity) AS OrderTotalPrice,
        CASE 
            WHEN SUM(bd.Price * at.Quantity) < 300 THEN 'Low Budget'
            WHEN SUM(bd.Price * at.Quantity) BETWEEN 300 AND 800 THEN 'Economy'
            WHEN SUM(bd.Price * at.Quantity) BETWEEN 800 AND 1100 THEN 'High End'
            ELSE 'Luxury'
        END AS OrderValueCategory
    FROM Orders o
    LEFT JOIN Carts cart ON o.CartID = cart.CartID
    LEFT JOIN AddedTo at ON cart.CartID = at.CartID
    LEFT JOIN BasicDesigns bd ON at.ModelName = bd.ModelName AND at.SessionID = bd.SessionID
    GROUP BY o.OrderID
),
CustomerMetrics AS (
    SELECT
        c.Email AS CustomerEmail,
        COUNT(o.OrderID) AS TotalOrders,
        AVG(om.OrderTotalPrice) AS AvgOrderPricePerCustomer,
        CASE 
            WHEN COUNT(o.OrderID) < 3 THEN 'New'
            WHEN COUNT(o.OrderID) BETWEEN 3 AND 6 THEN 'Regular'
            ELSE 'Loyal'
        END AS CustomerLoyaltyCategory
    FROM Customers c
    LEFT JOIN Carts cart ON c.Email = cart.Email
    LEFT JOIN Orders o ON cart.CartID = o.CartID
    LEFT JOIN OrderMetrics om ON o.OrderID = om.OrderID
    GROUP BY c.Email
)
SELECT
    -- Order Details
    o.OrderID,
    o.OrderDate,
    o.AddressCity AS City,
    o.AddressCountry AS Country,

    -- Cart Details
    cart.CartID,
    cart.CartDT AS CartDateTime,

    -- Customer Details
    c.Email AS CustomerEmail,
    c.[Customer Name] AS CustomerName,
    c.Phone AS CustomerPhone,
    c.Password AS CustomerPassword, -- Include the password column for subscription check

    -- Model Details
    m.ModelName,
    bd.SessionID,
    bd.Color AS DesignColor,
    bd.Price AS DesignPrice,

    -- Added To Cart Details
    at.Quantity,
    (bd.Price * at.Quantity) AS TotalPrice,

    -- Review Details
    r.Rate AS ReviewRating,
    bd.Color AS Color,

    -- Aggregated Metrics from Subqueries
    om.OrderTotalPrice,
    om.OrderValueCategory,
    cm.AvgOrderPricePerCustomer,
    cm.CustomerLoyaltyCategory,

    -- Is Subscriber
    CASE 
        WHEN c.Password IS NOT NULL AND c.Password <> '' THEN 'Yes'
        ELSE 'No'
    END AS IsSubscriber,

    -- Categorical Metric: Price Range of Products
    CASE 
        WHEN bd.Price < 200 THEN 'Economical'
        WHEN bd.Price BETWEEN 200 AND 500 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceRangeCategory,

    -- Categorical Metric: Order Season
    CASE 
        WHEN MONTH(o.OrderDate) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(o.OrderDate) IN (3, 4, 5) THEN 'Spring'
        WHEN MONTH(o.OrderDate) IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS OrderSeasonCategory,

    -- Aggregated Review Metrics
    AVG(r.Rate) OVER (PARTITION BY at.ModelName) AS AvgProductReviewRating,
    COUNT(r.Rate) OVER (PARTITION BY at.ModelName) AS TotalProductReviews

FROM Orders o
LEFT JOIN Carts cart ON o.CartID = cart.CartID
LEFT JOIN Customers c ON cart.Email = c.Email
LEFT JOIN AddedTo at ON cart.CartID = at.CartID
LEFT JOIN BasicDesigns bd ON at.ModelName = bd.ModelName AND at.SessionID = bd.SessionID
LEFT JOIN Models m ON bd.ModelName = m.ModelName
LEFT JOIN Reviews r ON r.ModelName = bd.ModelName AND r.Email = c.Email
LEFT JOIN OrderMetrics om ON o.OrderID = om.OrderID
LEFT JOIN CustomerMetrics cm ON c.Email = cm.CustomerEmail

WHERE o.OrderID IS NOT NULL; -- Ensure only rows with orders are included

SELECT * 
FROM PowerBI_View;


