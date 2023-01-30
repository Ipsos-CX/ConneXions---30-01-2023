ALTER TABLE [Vehicle].[PHEVModels]
	ADD CONSTRAINT [FK_PHEVModels_Models]
	FOREIGN KEY (ModelID)
	REFERENCES [Vehicle].[Models] ([ModelID])
