ALTER TABLE [dbo].[SubNationalRegions]
	ADD CONSTRAINT [FK_SubNationalRegions_Markets] 
	FOREIGN KEY (MarketID)
	REFERENCES dbo.Markets (MarketID)	

