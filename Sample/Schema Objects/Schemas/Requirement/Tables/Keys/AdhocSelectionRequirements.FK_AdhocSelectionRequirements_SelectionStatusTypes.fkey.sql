ALTER TABLE [Requirement].[AdhocSelectionRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionRequirements_SelectionStatusTypes] 
	FOREIGN KEY (SelectionStatusTypeID)
	REFERENCES Requirement.SelectionStatusTypes (SelectionStatusTypeID)

