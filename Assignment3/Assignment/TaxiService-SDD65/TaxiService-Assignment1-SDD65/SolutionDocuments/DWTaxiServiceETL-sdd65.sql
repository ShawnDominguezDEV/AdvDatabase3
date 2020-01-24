--		##### FLUSH #####

USE [DWTaxiService-sdd65]
GO


--Drop all foreign key restraints
ALTER TABLE dbo.FactTrips DROP CONSTRAINT [FK_FactTrips_DimDates]

ALTER TABLE dbo.FactTrips DROP CONSTRAINT [FK_FactTrips_DimLocation]

ALTER TABLE dbo.FactTrips DROP CONSTRAINT [FK_FactTrips_DimDriver]

ALTER TABLE dbo.DimLocation DROP CONSTRAINT [FK_DimLocation_DimCity]

GO

--TRUNCATE each table
TRUNCATE TABLE dbo.FactTrips

TRUNCATE TABLE dbo.DimLocation

TRUNCATE TABLE dbo.DimCity

TRUNCATE TABLE dbo.DimDriver

TRUNCATE TABLE dbo.DimDates

GO

--Add back FK restraints
ALTER TABLE [dbo].[FactTrips] WITH CHECK ADD CONSTRAINT [FK_FactTrips_DimDates] FOREIGN KEY ([DateKey])
REFERENCES [dbo].[DimDates] ([DateKey])
GO

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD CONSTRAINT [FK_FactTrips_DimLocation] FOREIGN KEY ([LocationKey])
REFERENCES [dbo].[DimLocation] ([LocationKey])
GO

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD CONSTRAINT [FK_FactTrips_DimDriver] FOREIGN KEY ([DriverKey])
REFERENCES [dbo].[DimDriver] ([DriverKey])
GO

ALTER TABLE [dbo].[DimLocation] WITH CHECK ADD CONSTRAINT [FK_DimLocation_DimCity] FOREIGN KEY([CityKey])
REFERENCES [dbo].[DimCity] ([CityKey])
GO


--		##### FILL #####

--Populate Tables with no FK. ~ DimCity | DimDriver | DimDate

INSERT INTO dbo.DimCity
( 
CityId,
CityName
)
(
SELECT
[CityId] = CAST ([City_Code] AS nchar(10) ),
[CityName] = CAST([CountryName] AS nvarchar(50))
FROM [TaxiServiceDB-sdd65].[dbo].[City]
)
GO

INSERT INTO dbo.DimDriver
(
DriverId,
DriverName
)
(
SELECT
[DriverId] = CAST([Driver_Id] as nchar(8)),
[DriverName] = CAST(isNull([FirstName], 'Unknown') + ' ' + (isNull([LastName], 'Unknown')) as nVarchar(50))
FROM [TaxiServiceDB-sdd65].[dbo].[Driver]
)
GO

--Populate DimDates---------------------------------------------------------------------------------------------------------------------------

Declare @StartDate datetime = '01/01/2010' 
Declare @EndDate datetime = '12/31/2011'
Declare @DateInProcess datetime
Set @DateInProcess = @StartDate
While @DateInProcess <= @EndDate
Begin
Insert Into DimDates
( [Date],
[DateName],
[Month],
[MonthName],
[Year],
[YearName]
)
Values
(
 @DateInProcess,
 DateName ( weekday, @DateInProcess ),
 Month( @DateInProcess ),
 DateName( month, @DateInProcess ),
 Year(@DateInProcess),
 Cast( Year(@DateInProcess ) as nVarchar(50) )
)

Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
End 
Set Identity_Insert [DWTaxiService-sdd65].[dbo].[DimDates] On
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
[DateKey] = -1,
[Date] = '01/01/2009',
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
[Date] = '01/01/2009',
[DateName] = Cast('Corrupt Day' as nVarchar(50)),
[Month] = -2,
[MonthName] = Cast('Corrupt Month' as nVarchar(50)),
[Year] = -2,
[YearName] = Cast('Corrupt Year' as nVarchar(50))
 )
Go
 Set Identity_Insert [DWTaxiService-sdd65].[dbo].[DimDates] off -- don't forget this!
GO
-------------------------------------------------------------------------------------------------------------------------------------
--Populate Tables with Foreign Keys ~ DimLocation | FactTrips

--Populate DimLocation --> 1 Foreign Key
INSERT INTO [dbo].[DimLocation]
(
CityKey,
StreetId,
Street
)
(
SELECT
[CityKey] = [DimCity].[CityKey],
[StreetId] = [Street_Code],
[Street] = CAST (isNull([StreetName], 'Unknown')as nvarchar(50))

FROM ([TaxiServiceDB-sdd65].[dbo].[Street] INNER JOIN DimCity
ON [TaxiServiceDB-sdd65].[dbo].[Street].[City_Code] = DimCity.CityId)
)
GO

--Populate FactTrips --> 3 Foreign Keys
INSERT INTO [dbo].[FactTrips]
(
TripNumber,
DateKey,
LocationKey,
DriverKey,
TripMileage,
TripCharge
)
(
SELECT
[TripNumber] = CAST ([number] as nvarchar(50) ),
[DateKey] = [DimDates].[DateKey],
[LocationKey] = [DimLocation].[LocationKey],
[DriverKey] = [DimDriver].[DriverKey],
[TripMileage] = CAST (isNull([milage], 'Unknown') as decimal(18, 4)),
[TripCharge] = CAST (isNull([charge], 'Unknown') as decimal(18, 4))

FROM (([TaxiServiceDB-sdd65].[dbo].[Trip]
INNER JOIN DimDates ON [TaxiServiceDB-sdd65].[dbo].[Trip].[Date] = DimDates.[Date])
INNER JOIN DimLocation ON [TaxiServiceDB-sdd65].[dbo].[Trip].[Street_Code] = DimLocation.[StreetId])
INNER JOIN DimDriver ON [TaxiServiceDB-sdd65].[dbo].[Trip].[Driver_Id] = DimDriver.[DriverId]
)
GO