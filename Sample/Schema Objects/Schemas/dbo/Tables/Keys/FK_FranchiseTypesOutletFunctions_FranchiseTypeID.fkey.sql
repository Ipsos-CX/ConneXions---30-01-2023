ALTER TABLE [dbo].[FranchiseTypesOutletFunctions]
	ADD CONSTRAINT [FK_FranchiseTypesOutletFunctions_FranchiseTypeID]
	FOREIGN KEY (FranchiseTypeID)
	REFERENCES dbo.FranchiseTypes (FranchiseTypeID)	
