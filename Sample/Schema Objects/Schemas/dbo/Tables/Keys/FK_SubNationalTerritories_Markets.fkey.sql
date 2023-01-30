ALTER TABLE [dbo].[SubNationalTerritories]
	ADD CONSTRAINT [FK_SubNationalTerritories_Markets] 
	FOREIGN KEY (MarketID)
	REFERENCES dbo.Markets (MarketID)	
