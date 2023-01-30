CREATE TABLE [Vehicle].[Models]
(
	ModelID								dbo.ModelID IDENTITY(1,1) NOT NULL, 
	ManufacturerPartyID					dbo.PartyID NOT NULL,
	ModelDescription					VARCHAR (50) NOT NULL,
	OutputFileModelDescription			VARCHAR (50) NOT NULL,
	EnprecisOutputFileModelDescription	VARCHAR (50) NULL,
	CodeName							VARCHAR (50) NULL,
	NorthAmericaModelDescription		VARCHAR (50) NULL,
	AllowSVO							BIT NULL, 
    SubBrandID							SMALLINT NULL
)
