ALTER TABLE [Party].[Organisations]
	ADD CONSTRAINT [DF_Organisations_UseLatestName]
	DEFAULT 0
	FOR [UseLatestName]
