CREATE TABLE [dbo].[SampleFileSpecialFormatting]
(
	[SpecialFormattingID]			INT NOT NULL IDENTITY(1,1), 
	[SampleFileID]					INT NOT NULL,
	[ColumnFormattingIdentifier]	NVARCHAR(100) NOT NULL,
	[ColumnFormattingValue]			NVARCHAR(100) NOT NULL,
	[Description]					NVARCHAR(200) NULL,
	[ThroughDate]					DATETIME2 NULL,

)
