USE [master]
GO
/****** Object:  Database [SalesManagement]    Script Date: 12/16/2018 12:30:16 PM ******/
CREATE DATABASE [SalesManagement]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SalesManagement', FILENAME = N'E:\Database\SQLExpress\SalesManagement.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'SalesManagement_log', FILENAME = N'E:\Database\SQLExpress\SalesManagement_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [SalesManagement] SET COMPATIBILITY_LEVEL = 140
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [SalesManagement].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [SalesManagement] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SalesManagement] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SalesManagement] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SalesManagement] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SalesManagement] SET ARITHABORT OFF 
GO
ALTER DATABASE [SalesManagement] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SalesManagement] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SalesManagement] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SalesManagement] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SalesManagement] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SalesManagement] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SalesManagement] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SalesManagement] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SalesManagement] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SalesManagement] SET  DISABLE_BROKER 
GO
ALTER DATABASE [SalesManagement] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SalesManagement] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SalesManagement] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [SalesManagement] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [SalesManagement] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SalesManagement] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [SalesManagement] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [SalesManagement] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [SalesManagement] SET  MULTI_USER 
GO
ALTER DATABASE [SalesManagement] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [SalesManagement] SET DB_CHAINING OFF 
GO
ALTER DATABASE [SalesManagement] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [SalesManagement] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [SalesManagement] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [SalesManagement] SET QUERY_STORE = OFF
GO
USE [SalesManagement]
GO
/****** Object:  UserDefinedFunction [dbo].[TotalRevenueOfMonth]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[TotalRevenueOfMonth](@month tinyint,@year smallint)
RETURNS decimal(25,3)
AS
BEGIN
	IF @month is null  OR @month = 0 OR @month > 12
		Set @month = DATEPART(MM,GetDate())
	IF @year is null OR @year > DATEPART(YYYY,GetDate())
		Set @year = DATEPART(YYYY,GetDate())
	DECLARE @fromDate datetime = Concat(@Year,'-',@Month,'-1')
	DECLARE @toDate datetime = DATEADD(MM,1,@FromDate)
	DECLARE @total decimal(25,3) = 
		(SELECT SUM(O.TotalPerOrder) AS  [Total]
		FROM(SELECT O.OrderID, O.CustomerID, TotalPerOrder = (SUM(OD.UnitPrice*OD.Quantity)+ O.Freight)
			FROM Orders O,  OrderDetails OD
			Where  O.OrderID  = OD.OrderID AND O.OrderDate >= @FromDate AND O.OrderDate < @toDate
		Group by O.OrderID, O.CustomerID, O.Freight) O)
	RETURN @total
END
GO
/****** Object:  UserDefinedFunction [dbo].[TotalRevenueOfQuarter]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[TotalRevenueOfQuarter](@quarter tinyint,@year smallint)
RETURNS decimal(30,3)
AS
BEGIN
	IF @year is null OR @year > DATEPART(YYYY,GetDate())
		Set @year = DATEPART(YYYY,GetDate())
	DECLARE @month tinyint 
	IF @quarter is null OR @quarter = 0 OR @quarter > 4
	BEGIN
		DECLARE @tempMonth tinyint = DATEPART(MM,GetDate())
		WHILE @tempMonth !=	 1 AND @tempMonth != 4 AND @tempMonth != 7 AND @tempMonth != 10
		BEGIN
			SET @tempMonth  = @tempMonth - 1
		END
		SET @month = @tempMonth
	END
	ELSE
		SET @month = (CASE
			WHEN @quarter = 1 then 1
			WHEN @quarter = 2 then 4
			WHEN @quarter = 3 then 7
			WHEN @quarter = 4 then 10
		END)
	DECLARE @fromDate datetime = Concat(@Year,'-',@Month,'-1')
	DECLARE @toDate datetime = DATEADD(MM,3,@FromDate)
	DECLARE @total decimal(30,3) = 
		(SELECT SUM(O.TotalPerOrder) AS  [Total]
		FROM(SELECT O.OrderID, O.CustomerID, TotalPerOrder = (SUM(OD.UnitPrice*OD.Quantity)+ O.Freight)
			FROM Orders O,  OrderDetails OD
			Where  O.OrderID  = OD.OrderID AND O.OrderDate >= @FromDate AND O.OrderDate < @toDate
		Group by O.OrderID, O.CustomerID, O.Freight) O)
	RETURN @total
END
GO
/****** Object:  UserDefinedFunction [dbo].[TotalSpendOfCustomers]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Function [dbo].[TotalSpendOfCustomers](@month tinyint, @year smallint)
RETURNS @Table Table
(
	CustomerID int,
	[Name] nvarchar(60),
	[TotalPurchased] int,
	[Total] decimal(18,3)
)
AS
BEGIN
	IF @month is null  OR @month = 0 OR @month > 12
		Set @month = DATEPART(MM,GetDate())
	IF @year is null OR @year > DATEPART(YYYY,GetDate())
		Set @year = DATEPART(YYYY,GetDate())
	DECLARE @fromDate datetime = Concat(@Year,'-',@Month,'-1')
	DECLARE @toDate datetime = DATEADD(MM,1,@FromDate)
	INSERT INTO @Table
		SELECT O.CustomerID AS [CustomerID], C.[Name] AS [Name],Count(*) AS [TotalPurchased],SUM(O.TotalPerOrder) AS  [Total]
		FROM(
			SELECT O.OrderID, O.CustomerID, TotalPerOrder = (SUM(OD.UnitPrice*OD.Quantity)+ O.Freight)
			FROM Orders O,  OrderDetails OD
			Where  O.OrderID  = OD.OrderID AND O.OrderDate >= @fromDate AND O.OrderDate < @toDate
			Group by O.OrderID, O.CustomerID, O.Freight
			) O, Customers C
		WHERE O.CustomerID = C.CustomerID
		GROUP BY O.CustomerID, C.[Name]
	Return 
END
GO
/****** Object:  Table [dbo].[Customers]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customers](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](60) NOT NULL,
	[Gender] [bit] NOT NULL,
	[PhoneNumber] [varchar](10) NOT NULL,
	[Address] [nvarchar](200) NULL,
	[Email] [nvarchar](max) NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Employees]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employees](
	[EmployeeID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](60) NOT NULL,
	[BirthDate] [date] NOT NULL,
	[Gender] [bit] NOT NULL,
	[ID] [varchar](12) NOT NULL,
	[PhoneNumber] [varchar](10) NOT NULL,
	[Address] [nvarchar](200) NULL,
	[JobTitle] [nvarchar](10) NULL,
 CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OrderDetails]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrderDetails](
	[OrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[UnitPrice] [decimal](10, 3) NOT NULL,
	[Quantity] [int] NOT NULL,
 CONSTRAINT [PK_OrderDetails] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Orders]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Orders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[CustomerID] [int] NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[Freight] [decimal](10, 3) NOT NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Products]    Script Date: 12/16/2018 12:30:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[ProductName] [nvarchar](50) NOT NULL,
	[AddedDate] [datetime] NOT NULL,
	[QuantityPerUnit] [nvarchar](30) NULL,
	[UnitPrice] [decimal](10, 0) NOT NULL,
	[UnitsInStock] [int] NOT NULL,
	[UnitsOnOrder] [int] NOT NULL,
	[Discontinued] [bit] NOT NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OrderDetails] ADD  CONSTRAINT [DF_OrderDetails_UnitPrice]  DEFAULT ((0)) FOR [UnitPrice]
GO
ALTER TABLE [dbo].[OrderDetails] ADD  CONSTRAINT [DF_OrderDetails_Quantity]  DEFAULT ((0)) FOR [Quantity]
GO
ALTER TABLE [dbo].[Orders] ADD  CONSTRAINT [DF_Orders_Freight]  DEFAULT ((0)) FOR [Freight]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_UnitPrice]  DEFAULT ((0)) FOR [UnitPrice]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_UnitsInStock]  DEFAULT ((0)) FOR [UnitsInStock]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_UnitsOnOrder]  DEFAULT ((0)) FOR [UnitsOnOrder]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_Discontinued]  DEFAULT ((0)) FOR [Discontinued]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Orders] FOREIGN KEY([OrderID])
REFERENCES [dbo].[Orders] ([OrderID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Orders]
GO
ALTER TABLE [dbo].[OrderDetails]  WITH CHECK ADD  CONSTRAINT [FK_OrderDetails_Products] FOREIGN KEY([ProductID])
REFERENCES [dbo].[Products] ([ProductID])
GO
ALTER TABLE [dbo].[OrderDetails] CHECK CONSTRAINT [FK_OrderDetails_Products]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Customers] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[Customers] ([CustomerID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Customers]
GO
ALTER TABLE [dbo].[Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Employees] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employees] ([EmployeeID])
GO
ALTER TABLE [dbo].[Orders] CHECK CONSTRAINT [FK_Orders_Employees]
GO
ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [CK_Products_UnitsInStock] CHECK  (([UnitsInStock]>=(0)))
GO
ALTER TABLE [dbo].[Products] CHECK CONSTRAINT [CK_Products_UnitsInStock]
GO
ALTER TABLE [dbo].[Products]  WITH CHECK ADD  CONSTRAINT [CK_Products_UnitsOnOrder] CHECK  (([UnitsOnOrder]>=(0)))
GO
ALTER TABLE [dbo].[Products] CHECK CONSTRAINT [CK_Products_UnitsOnOrder]
GO
USE [master]
GO
ALTER DATABASE [SalesManagement] SET  READ_WRITE 
GO
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (1, N'Dầu ăn Neptune 400ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(15000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (3, N'Dầu ăn Neptune 1l', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(41500 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (4, N'Dầu ăn Mezan 2l', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(62000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (5, N'Dầu ăn Simply 2l', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(86000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (6, N'Dầu ăn Simply 5l', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(210000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (7, N'Dầu ăn Mezan 5l', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(205000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (8, N'Bột canh gà angon 200g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Gói', CAST(3000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (9, N'Bột mì MeZan 500g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Gói', CAST(8000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (10, N'Bột mì Mezan 1kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Gói', CAST(13500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (11, N'SRM Nivia sạch nhờn', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(34000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (12, N'SRM Nivia trắng da', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(36000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (13, N'SRM Nivia nhờn Nam', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(60000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (14, N'SRM Nivia mờ thâm Nam', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(48000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (15, N'Dầu gội Clear 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(58000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (16, N'Dầu gội Xmen 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(61000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (17, N'Dầu gội Lux 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(60000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (18, N'Dầu gội Dove 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(55000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (19, N'Dầu gội H&S 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(58000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (20, N'Dầu gội Xmen 450ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(135000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (21, N'Dầu gội Lux 450ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(130000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (22, N'Dầu gội Dove 450ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(132000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (23, N'Dầu gội H&S 450ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(140000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (24, N'Sữa tắm Enchanter 180ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(40000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (25, N'Sữa tắm Enchanter 650ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(138000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (26, N'Sáp khử mùi EN', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(59000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (27, N'Nước hoa Izi', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(36500 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (28, N'Xúc xích heo 6 cây', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Túi', CAST(16000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (30, N'Xúc xích bò 6 cây', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Túi', CAST(18000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (31, N'Thịt hộp pate heo', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(24000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (32, N'Thịt hộp heo hầm ', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(35000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (33, N'Thịt hộp bò xay', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(24000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (34, N'Thịt hộp bò hầm', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(25000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (35, N'Khẩu trang Eros size L', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Gói', CAST(25000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (36, N'Bột giặt Aba 5kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(146000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (37, N'Bột Giặt Aba 2kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(89000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (38, N'Bột giặt Aba 800g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(35000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (39, N'Bột Giặt Omo 800g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(42000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (40, N'Bột giặt Omo 2kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(90000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (41, N'Bột giặt Omo 5kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(150000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (42, N'Bí đaoThạch BÍch', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lon', CAST(8000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (43, N'Nước Khoáng 500ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(10000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (44, N'Nước khoáng 350ml', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(8000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (45, N'Nước Yến Thạch Bích', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lon', CAST(12000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (46, N'Vedan 1kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(48000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (47, N'Vedan 2kg', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(90000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (48, N'Vedan 400g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(25000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (49, N'SRM Biore sạch mụn', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(32000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (50, N'SRM Biore Sạch nhờn', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lọ', CAST(30000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (51, N'Nuti IQ 123', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(300000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (52, N'Nuti IQ 456', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(320000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (53, N'Nuti IQ 123 Gold', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(350000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (54, N'Nuti IQ 456 Gold', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(380000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (55, N'Nuti Grow', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(250000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (56, N'Nuti pedia', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(200000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (57, N'Fami', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(5000 AS Decimal(10, 0)), 1000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (58, N'Fami Canxi', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(5500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (59, N'Milo', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(8000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (60, N'Milo Bịch', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(7000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (61, N'Sữa bò Vinamilk', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(7500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (62, N'Sữa bò Vinamilk bịch', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Hộp', CAST(7000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (63, N'Hạt Nêm Magi 900g', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(55000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (64, N'Nước tương Magi', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Bịch', CAST(26500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (65, N'Dầu hào Magi', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(18000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (66, N'C2', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(7000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (67, N'Bò Húc Red Bull', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(12000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (68, N'Twister', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(8500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (69, N'Twister lon', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lon', CAST(10000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (70, N'Ice Chanh', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(8000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (71, N'Ice Đào', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(8000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (72, N'Sting', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(9000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (73, N'Sting lon', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Lon', CAST(10000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (74, N'Coca-Cola', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 Chai', CAST(8500 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (75, N'Coca-cola lon', CAST(N'2018-12-17T00:00:00.000' AS DateTime), N'1 lon', CAST(10000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (77, N'Number 1', CAST(N'2018-12-17T18:37:38.400' AS DateTime), N'1 Chai', CAST(10000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (78, N'Number 1 Lon', CAST(N'2018-12-17T18:39:12.600' AS DateTime), N'1 Lon', CAST(11000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (79, N'Fanta lon', CAST(N'2018-12-17T18:40:18.703' AS DateTime), N'1 Lon', CAST(9000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (80, N'Fanta', CAST(N'2018-12-17T18:40:34.697' AS DateTime), N'1 Chai', CAST(8000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (81, N'pepsi', CAST(N'2018-12-17T18:41:41.610' AS DateTime), N'1 Chai', CAST(9000 AS Decimal(10, 0)), 10000, 0, 0)
INSERT [dbo].[Products] ([ProductID], [ProductName], [AddedDate], [QuantityPerUnit], [UnitPrice], [UnitsInStock], [UnitsOnOrder], [Discontinued]) VALUES (82, N'Pepsi Lon', CAST(N'2018-12-17T18:42:17.320' AS DateTime), N'1 Lon', CAST(10000 AS Decimal(10, 0)), 10000, 0, 0)