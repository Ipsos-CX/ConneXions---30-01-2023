ALTER TABLE [Vehicle].[PHEVModels]
	ADD CONSTRAINT [PK_PHEVModels]
	PRIMARY KEY ([ModelID] ASC, [VINPrefix] ASC, [VINCharacter] ASC)
