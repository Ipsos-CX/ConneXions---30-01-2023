ALTER TABLE [dbo].[Markets]
	ADD CONSTRAINT [DF_Markets_UseLatestName]
	DEFAULT 0
	FOR [UseLatestName]
