CREATE TABLE [GDPR].[PostalAddresses] (
	ID INT,
	[Building Name] NVARCHAR(400), 
	[Sub Street Number] NVARCHAR(400), 
	[Sub Street] NVARCHAR(400), 
	[Street Number] NVARCHAR(400), 
	[Street] NVARCHAR(400), 
	[Sub Locality] NVARCHAR(400), 
	[Locality] NVARCHAR(400), 
	[Town] NVARCHAR(400), 
	[Region] NVARCHAR(400), 
	[PostCode] NVARCHAR(400), 
	[Country] NVARCHAR(400), 
	[Permission to Contact By Post?] NVARCHAR(400),
	[Best Postal Address?] NVARCHAR(400)
	) ON [PRIMARY]
