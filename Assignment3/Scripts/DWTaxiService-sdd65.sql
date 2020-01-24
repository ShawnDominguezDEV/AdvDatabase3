-- SQL Script for Full Loading or 'Flush and Fill' using the Truncate technique

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
/*  The following SQL Script flushes the data warehouse */
/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

USE [DWTaxiService-sdd65]
GO

ALTER TABLE [dbo].[FactTrips] DROP CONSTRAINT [FK_FactTrips_DimDriver]
ALTER TABLE [dbo].[FactTrips] DROP CONSTRAINT [FK_FactTrips_DimLocation]
ALTER TABLE [dbo].[FactTrips] DROP CONSTRAINT [FK_FactTrips_DimDates]
ALTER TABLE [dbo].[DimLocation] DROP CONSTRAINT [FK_DimLocation_DimCity]


Go

-- Now Truncate each table

TRUNCATE TABLE [dbo].[DimCity]
TRUNCATE TABLE [dbo].[DimDates]
TRUNCATE TABLE [dbo].[DimDriver]
TRUNCATE TABLE [dbo].[DimLocation]
TRUNCATE TABLE [dbo].[FactTrips]

-- ----------------------------------------------------------------------------------------------------------
-- Add back all foreign Key constraints

ALTER TABLE [dbo].[DimLocation]  WITH CHECK ADD  CONSTRAINT [FK_DimLocation_DimCity] FOREIGN KEY([CityKey])
REFERENCES [dbo].[DimCity] ([CityKey])

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimDates] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDates] ([DateKey])

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimDriver] FOREIGN KEY([DriverKey])
REFERENCES [dbo].[DimDriver] ([DriverKey])

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimLocation] FOREIGN KEY([LocationKey])
REFERENCES [dbo].[DimLocation] ([LocationKey])

/*--------------------------------------------------------------------------------------------------------------------------------------------------------------*/
/* The following script transforms and then loads  (FILLS) data from OLTP Pubs database into OLAP DWPubSales Data Warehouse */
/*--------------------------------------------------------------------------------------------------------------------------------------------------------------*/

-- First populate tables with No Foreign Keys.   - DimStores, DimPublishers, and DimDate tables

INSERT INTO dbo.DimCity
(	
	CityId,
	CityName
) 
(
	SELECT 
		[CityID]		= CAST ([City_Code] AS nchar(10) ),
		[CityName]		= CAST ( [CountryName] as nvarchar(50) )
	FROM [TaxiServiceDB-sdd65].[dbo].[City]
)
go

INSERT INTO dbo.DimDriver
(	[DriverId] , 
	[DriverName]
) 
(
	SELECT 
		[DriverId]  =  CAST ( [Driver_Id] AS nchar(8) ),
		[DriverName] = CAST ( isNull(RTRIM([FirstName]) + ' ' + RTrim([LastName]), 'Unknown' ) as nvarchar(50) )		
	FROM [TaxiServiceDB-sdd65].[dbo].[Driver]
)
go


-- Populate the DimDate table. Since no source data exists, we will have to do this programmatically -- see separate script
-- the following SQL script Populates DimDate table with dates between 1990 and 1995


Declare @StartDate datetime = '01/01/2010'   /* variable @StartDate of type DateTime is initialized the start date '01/01/1990' */
Declare @EndDate datetime = '12/31/2020' 

-- Use a while loop to add dates to the table
Declare @DateInProcess datetime                 /* Variable @DateInProcess is a loop counter, holds the date value being processeds, and will track when loop needs to end */
Set @DateInProcess = @StartDate

While @DateInProcess <= @EndDate
 Begin
 -- Add a row into the date dimension table for this date
 Insert Into DimDates
 (	[Date], 
	[DateName], 
	[Month], 
	[MonthName], 
	[Year], 
	[YearName] 
 )
 Values 
 ( 
	  @DateInProcess,										-- [Date]
	  DateName ( weekday, @DateInProcess ),					-- [DateName]  
	  Month( @DateInProcess ),								-- [Month]   
	  DateName( month, @DateInProcess ),					-- [MonthName]
	  Year( @DateInProcess),
	  Cast( Year(@DateInProcess ) as nVarchar(50) )			 -- [Year] 
 )  
 -- Add a day and loop again
 Set @DateInProcess = DateAdd(d, 1, @DateInProcess)

 End  -- END OF DATE LOOP

 --Add two more date records to handle nulls and incorrect date data

Set Identity_Insert [DWTaxiService-sdd65].[dbo].[DimDates] On

Insert Into [dbo].[DimDates] 
  ( [DateKey],
	[Date],
	[DateName], 
	[Month],
	[MonthName],
	[Year], 
	[YearName] 
  )
  (
	  Select 
		[DateKey] = -1,
		[Date] =  '01/01/1989',
		[DateName] = Cast('Unknown Day' as nVarchar(50)),
		[Month] = -1,
		[MonthName] = Cast('Unknown Month' as nVarchar(50)),
		[Year] = -1,
		[YearName] = Cast('Unknown Year' as nVarchar(50))
  )
  Insert Into [dbo].[DimDates] 
  ( 
		[DateKey],
		[Date],
		[DateName], 
		[Month],
		[MonthName],
		[Year], 
		[YearName] 
  )
  (
	  Select 
		[DateKey] = -2, 
		[Date] = '01/02/1989', 
		[DateName] = Cast('Corrupt Day' as nVarchar(50)),
		[Month] = -2, 
		[MonthName] = Cast('Corrupt Month' as nVarchar(50)),
		[Year] = -2,
		[YearName] = Cast('Corrupt Year' as nVarchar(50))
  )
Go

  Set Identity_Insert [DWTaxiService-sdd65].[dbo].[DimDates] off  -- don't forget this!
  go
/*------------------------------------------------------------------
-- Next populate the tables with only one FK constraint - DimTitles
--------------------------------------------------------------------*/

INSERT INTO [dbo].[DimLocation]
( 
	CityKey, 
	StreetId, 
	Street
)
(
	SELECT  
		CityKey =  [DimCity].[CityKey],
		StreetId = CAST( Street_Code as nchar(10) ),
		Street =   CAST( isNull( [StreetName], 'Unknown') as nVarchar(50) )
	
	FROM ( [TaxiServiceDB-sdd65].[dbo].[Street]  INNER JOIN  DimCity
		ON [TaxiServiceDB-sdd65].[dbo].[Street].[City_Code] = DimCity.CityID)
			
)
GO


INSERT INTO [dbo].[FactTrips]
(
	DateKey,
	LocationKey,
	DriverKey,
	TripNumber,
	TripMileage,
	TripCharge
 )
 (
	SELECT        
		DateKey = [DimDates].[DateKey],
		LocationKey = [DimLocation].[LocationKey], 
		DriverKey = [DimDriver].[DriverKey],
		TripNumber = Cast([number] as nVarchar(50)),
		TripMileage = Cast( isNull([milage], -1) as decimal(18,4)),
		TripCharge = Cast( isNull([charge], -1) as decimal(18,4))
	
	FROM            
		((([TaxiServiceDB-sdd65].[dbo].[Trip] as T INNER JOIN DimLocation
			ON T.Street_Code = DimLocation.StreetId)
			  inner join DimDriver on DimDriver.DriverID = T.Driver_Id)
				inner join DimDates on DimDates.[Date] = T.[Date])
)