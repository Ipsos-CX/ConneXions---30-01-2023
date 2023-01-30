CREATE TABLE [CRM].[Filters](
	[FilterID] [int] IDENTITY(1,1) NOT NULL,
	[FilterName]   VARCHAR(256) NOT NULL,
	[FilterDescription] VARCHAR(512) NOT NULL,
	[Enabled]	BIT NOT NULL
) ON [PRIMARY]