ALTER TABLE [Audit].[Organisations]
	ADD CONSTRAINT [DF_Organisations_UseLatestName]
	DEFAULT 0
	FOR [UseLatestName]
