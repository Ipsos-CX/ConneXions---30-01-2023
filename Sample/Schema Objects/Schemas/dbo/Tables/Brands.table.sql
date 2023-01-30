CREATE TABLE [dbo].[Brands]
(
	BrandID INT NOT NULL IDENTITY(1,1), 
	Brand  dbo.OrganisationName NOT NULL,
	ManufacturerPartyID dbo.ManufacturerPartyID NOT NULL
)
