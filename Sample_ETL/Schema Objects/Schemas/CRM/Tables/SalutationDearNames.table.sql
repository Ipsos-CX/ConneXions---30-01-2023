CREATE TABLE [CRM].[SalutationDearNames](
	[SalutationDearNameID] [int] IDENTITY(1,1) NOT NULL,
	[CountryISOAlpha2]  CHAR(2) NOT NULL,
	[Gender]			CHAR(1) NOT NULL,
	[DearName]	NVARCHAR(100) NOT NULL
) ON [PRIMARY]