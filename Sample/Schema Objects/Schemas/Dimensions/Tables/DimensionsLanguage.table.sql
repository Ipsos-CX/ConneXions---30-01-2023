CREATE TABLE [Dimensions].[DimensionsLanguage](
	[DimensionsLanguageID]	[int] IDENTITY(1,1)		NOT NULL,
	[Language]				[nvarchar](255)			NOT NULL,
	[LanguageCode]			[varchar](3)			NOT NULL,
	[LanguageID]			[dbo].[LanguageID]		NULL
)