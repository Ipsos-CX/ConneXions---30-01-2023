ALTER TABLE [Audit].[Markets]
	ADD CONSTRAINT [DF_Markets_UseLatestName]
	DEFAULT 0
	FOR [UseLatestName]
