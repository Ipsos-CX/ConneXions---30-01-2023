ALTER TABLE [Requirement].[AdhocSelectionRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionRequirements_SelectionTypes] 
	FOREIGN KEY (SelectionTypeID)
	REFERENCES Requirement.SelectionTypes (SelectionTypeID)	

