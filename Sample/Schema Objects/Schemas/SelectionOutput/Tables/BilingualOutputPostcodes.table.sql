CREATE TABLE [SelectionOutput].[BilingualOutputPostcodes] (
	BilingualOutputPostcodeID	INT NOT NULL IDENTITY(1,1),
	CountryID					dbo.CountryID	NOT NULL,
	PostCodeMatchString			dbo.Postcode	NOT NULL,
	Enabled						BIT				NOT NULL
);

