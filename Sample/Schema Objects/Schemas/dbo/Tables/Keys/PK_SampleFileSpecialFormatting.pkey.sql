ALTER TABLE [dbo].[SampleFileSpecialFormatting] 
	ADD  CONSTRAINT [PK_SampleFileSpecialFormatting] 
	PRIMARY KEY CLUSTERED 
	(
		[SampleFileID] ASC,
		[ColumnFormattingIdentifier] ASC,
		[ColumnFormattingValue] ASC
	)