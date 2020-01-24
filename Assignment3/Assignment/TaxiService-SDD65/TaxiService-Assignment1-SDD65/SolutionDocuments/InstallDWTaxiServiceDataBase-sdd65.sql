--Check to ensure the database does not already exist before creating it.
USE [master]
GO

if EXISTS (SELECT name from sys.databases WHERE name = N'DWTaxiService-sdd65')
	BEGIN
		ALTER DATABASE [DWTaxiService-sdd65] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE [DWTaxiService-sdd65]
	END
GO


CREATE DATABASE [DWTaxiService-sdd65]
GO


--Switch focus to new database

USE [DWTaxiService-sdd65]
GO

--Create Tables

--DimDriver Table
CREATE TABLE dbo.DimDriver
(
	DriverKey int NOT NULL IDENTITY,
	DriverId nchar(8) NOT NULL,
	DriverName nvarchar(50) NOT NULL,
	CONSTRAINT [PK_DimDriver] PRIMARY KEY ([DriverKey] ASC)
)
	
GO

--DimCity Table
CREATE TABLE dbo.DimCity
(
	CityKey int NOT NULL IDENTITY,
	CityId	nchar(10) NOT NULL,	
	CityName nchar(50) NOT NULL,
	CONSTRAINT [PK_DimCity] PRIMARY KEY ([CityKey] ASC)		--Double check
)
	
GO

--DimDates Table
CREATE TABLE dbo.DimDates
(
	DateKey int NOT NULL IDENTITY,
	[Date] datetime NOT NULL,
	[DateName] nvarchar(50) NOT NULL,
	[Month] int NOT NULL,
	[MonthName] nvarchar(50) NOT NULL,
	[Year] int NOT NULL,
	[YearName] nvarchar(50) NOT NULL,
	CONSTRAINT [PK_DimDates] PRIMARY KEY ([DateKey] ASC)
)
	
GO

--DimLocation Table
CREATE TABLE dbo.DimLocation
(
	LocationKey int NOT NULL IDENTITY,	
	CityKey int NOT NULL,
	StreetId nchar(10) NOT NULL,
	Street nchar(50) NOT NULL,
	CONSTRAINT [PK_DimLocation] PRIMARY KEY ([LocationKey] ASC)
)
	
GO

--FactTrips Table
CREATE TABLE dbo.FactTrips
(
	TripKey int NOT NULL IDENTITY,
	TripNumber nvarchar(50) NOT NULL,
	DateKey int NOT NULL,
	LocationKey int NOT NULL,
	DriverKey int NOT NULL,
	TripMileage decimal(18, 4) NOT NULL,
	TripCharge decimal(18, 4) NOT NULL,
	CONSTRAINT [PK_FactTrips] PRIMARY KEY ([TripKey] ASC)
)

GO

--Define Foreign Keys
ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimDates] FOREIGN KEY([DateKey])
REFERENCES [dbo].[DimDates] ([DateKey])
GO

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimLocation] FOREIGN KEY([LocationKey])
REFERENCES [dbo].[DimLocation] ([LocationKey])
GO

ALTER TABLE [dbo].[FactTrips]  WITH CHECK ADD  CONSTRAINT [FK_FactTrips_DimDriver] FOREIGN KEY([DriverKey])
REFERENCES [dbo].[DimDriver] ([DriverKey])
GO

ALTER TABLE [dbo].[DimLocation]  WITH CHECK ADD  CONSTRAINT [FK_DimLocation_DimCity] FOREIGN KEY([CityKey])
REFERENCES [dbo].[DimCity] ([CityKey])
GO

--Notify if successful
Select Message = 'DWTaxiService-sdd65 OLAP Database successfully created !' 