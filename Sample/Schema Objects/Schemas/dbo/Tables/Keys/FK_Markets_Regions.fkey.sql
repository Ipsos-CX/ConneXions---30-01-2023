ALTER TABLE [dbo].[Markets]
	ADD CONSTRAINT [FK_Markets_Regions] 
	FOREIGN KEY (RegionID)
	REFERENCES dbo.Regions (RegionID)	

