ALTER TABLE [dbo].[Regions]
	ADD CONSTRAINT [FK_Regions_SuperNationalRegions] 
	FOREIGN KEY (SuperNationalRegionID)
	REFERENCES dbo.SuperNationalRegions (SuperNationalRegionID)	
