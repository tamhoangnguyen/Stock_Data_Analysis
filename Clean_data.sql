USE CHUNGKHOAN

GO

-- Tạo bảng view để group data các tháng thành 1 bảng
CREATE VIEW table_1 AS
WITH table_1  ( Day_Trading,StockCode,Closing_Price,Opening_Price, Highest_Price,Lowest_Price, New_Change, Plus_Minus )
AS
(
	SELECT GROUP_TABLE.Day_Trading,GROUP_TABLE.StockCode,
		GROUP_TABLE.Closing_Price,GROUP_TABLE.Opening_Price,GROUP_TABLE.Highest_Price,
		GROUP_TABLE.Lowest_Price,GROUP_TABLE.New_Change,GROUP_TABLE.Plus_Minus
	FROM 
	(
		SELECT * FROM [dbo].[Information_2023_1]
		UNION
		SELECT * FROM [dbo].[Information_2023_2]
		UNION
		SELECT * FROM [dbo].[Information_2023_3]
		UNION
		SELECT * FROM [dbo].[Information_2023_4]
	) AS GROUP_TABLE
) SELECT * FROM table_1

GO

-- Truy vấn Join 3 bảng COMPANY, DATA_MAJOR, table_1 lấy ra Name_Company và Majority
SELECT t1.StockCode, t2.Name_Company, t2.Majority
FROM table_1 as t1
LEFT JOIN (
	SELECT DM.* ,CP.*
	FROM DATA_MAJOR DM
	FULL OUTER JOIN COMPANY CP
	ON DM.Stock_code = CP.Company_Code
	WHERE Exchange is not NULL ) as t2
ON t1.StockCode = t2.Stock_code

GO

-- Tạo view kết hợp truy vấn ở trên để tạo ra 1 bảng table_1 có thêm Name_Company, Majority
CREATE VIEW table_2 AS
WITH table_2 ( Day_Trading, StockCode, Closing_Price,Opening_Price, Highest_Price, Lowest_Price, New_Change,Plus_Minus,Name_Company, Majority, Company_ID )
AS
(
	SELECT t1.* ,t2.Name_Company,t2.Majority,t2.Company_ID
	FROM table_1 as t1
	LEFT JOIN (
		SELECT DM.* ,CP.*
		FROM DATA_MAJOR DM
		FULL OUTER JOIN COMPANY CP
		ON DM.Stock_code = CP.Company_Code
		WHERE Exchange = 'HOSE' ) 
		as t2
	ON t1.StockCode = t2.Stock_code
	WHERE Name_Company is not NULL
)
SELECT * FROM table_2

GO

-- Xếp hạng giá đóng cửa của công ty theo tháng
CREATE VIEW table_3 AS WITH table_3 ( StockCode, month_trading, Max_Closing_Price )
AS
(
	SELECT v1.StockCode,month(v1.Day_Trading) as month_trading, max(v1.Closing_Price) as Max_Closing_Price
	FROM table_2 as v1
	GROUP BY v1.StockCode,month(v1.Day_Trading)
)
SELECT * , RANK() OVER ( PARTITION BY StockCode ORDER BY Max_Closing_Price DESC ) as rank_price
FROM table_3

SELECT * FROM table_3

GO


GO

-- Tạo bảng view để xem xét tỉ lệ lợi nhuận của từng tháng của mỗi công ty
CREATE VIEW table_4 AS WITH table_4 (StockCode,month_trading,Max_Closing_Price,max_price_last_month )
AS
(
	SELECT nt1.StockCode,nt1.month_trading,nt1.Max_Closing_Price,nt2.Max_Closing_Price as max_price_last_month
	FROM table_3 as nt1
	LEFT JOIN 
	(
		SELECT * FROM table_3 where month_trading >= ( SELECT min(month_trading) FROM table_3 ) 
	) as nt2
	ON nt1.StockCode = nt2.StockCode and nt1.month_trading - 1 = nt2.month_trading 
) 
SELECT * FROM table_4

SELECT * FROM table_4 ORDER BY 1 ASC, 2 DESC

GO

-- Tính tỉ lệ lợi nhuận của công ty
CREATE VIEW PCT_change AS
WITH PCT_Change ( StockCode, month_trading, Max_closing_Price, Max_Price_last_month, PCT_change)
AS
(
	SELECT *, (cast(Max_Closing_Price as float) - cast(max_price_last_month as float)) / max_price_last_month * 100 as PCT_change 
	FROM table_4
)
SELECT * FROM PCT_Change

GO

WITH Note_PCT_stocks_fell AS 
(
	SELECT PC.StockCode, sum(PCT_change) as sum_PCT,
		Case WHEN sum(PCT_change) < 0 then N'Cổ phiếu giảm' else N'Cổ phiếu tăng' end as Note
	FROM PCT_change as PC
	WHERE PC.PCT_change is not NULL
	GROUP BY StockCode
) SELECT StockCode,sum_PCT, DENSE_RANK() OVER (PARTITION BY Note ORDER BY sum_PCT ASC) as rank_number ,Note 
INTO Note_PCT_stocks_fell
FROM Note_PCT_stocks_fell WHERE Note = N'Cổ phiếu giảm'

GO

WITH Note_PCT_stocks_rise AS 
(
	SELECT PC.StockCode, sum(PCT_change) as sum_PCT,
		Case WHEN sum(PCT_change) < 0 then N'Cổ phiếu giảm' else N'Cổ phiếu tăng' end as Note
	FROM PCT_change as PC
	WHERE PC.PCT_change is not NULL
	GROUP BY StockCode
) SELECT StockCode,sum_PCT, DENSE_RANK() OVER (PARTITION BY Note ORDER BY sum_PCT DESC) as rank_number ,Note 
INTO Note_PCT_stocks_rise
FROM Note_PCT_stocks_rise WHERE Note = N'Cổ phiếu tăng'

-- Tạo 2 bảng để tiến hành phân tích
SELECT data_1.StockCode,data_2.Name_Company,data_2.Company_ID,data_2.Majority ,data_1.sum_PCT,data_1.rank_number as rank_pct_change,data_1.Note
INTO Data_Visualization_1
FROM 
(
	SELECT * from Note_PCT_stocks_fell
	UNION
	SELECT * from Note_PCT_stocks_rise
) AS data_1
LEFT JOIN 
(
	SELECT CP.Company_Code as StockCode, CP.Full_Name as Name_Company , CP.Company_ID, DJ.Majority
	FROM COMPANY as CP
	LEFT JOIN DATA_MAJOR as DJ
	ON CP.Company_Code = DJ.Stock_Code
) as data_2
ON data_1.StockCode = data_2.StockCode
ORDER BY  Note DESC,rank_pct_change 

SELECT data_3.Day_Trading,data_3.StockCode,data_3.Closing_Price, data_3.Opening_Price, data_3.Highest_Price, data_3.Lowest_Price,DJ.Majority
INTO Data_Visualization_2
FROM 
(
	SELECT * FROM [dbo].[Information_2023_1]
	UNION
	SELECT * FROM [dbo].[Information_2023_2]
	UNION
	SELECT * FROM [dbo].[Information_2023_3]
	UNION
	SELECT * FROM [dbo].[Information_2023_4]
) as data_3
LEFT JOIN DATA_MAJOR as DJ
ON data_3.StockCode = DJ.Stock_code

SELECT * FROM Data_Visualization_1 
SELECT * FROM Data_Visualization_2