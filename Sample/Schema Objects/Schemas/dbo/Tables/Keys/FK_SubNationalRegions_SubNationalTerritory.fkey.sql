ALTER TABLE [dbo].[SubNationalRegions]
	ADD CONSTRAINT [FK_SubNationalRegions_SubNationalTerritories] 
	FOREIGN KEY (SubNationalTerritoryID)
	REFERENCES dbo.SubNationalTerritories (SubNationalTerritoryID)	

