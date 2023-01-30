CREATE TABLE [CRM].[SalutationBuildData](
	[SalutationBuildDataID] [int] IDENTITY(1,1) NOT NULL,
	[CountryISOAlpha2]  CHAR(2) NOT NULL,
	[TitlePart]			VARCHAR(50) NOT NULL,
	[TitlePartValue]	NVARCHAR(100) NOT NULL,
	[Translation]		NVARCHAR(100) NOT NULL,
	[OutputValue]		NVARCHAR(100) NULL,
	[Gender]			CHAR(1) NULL,
	[ClearTitle]		BIT NOT NULL DEFAULT 0,
	[ClearPrefix]		BIT NOT NULL DEFAULT 0,
	[ClearLastName]		BIT NOT NULL DEFAULT 0
) ON [PRIMARY]