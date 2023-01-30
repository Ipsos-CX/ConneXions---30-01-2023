ALTER TABLE [dbo].[FranchiseTypesOutletFunctions]
	ADD CONSTRAINT [FK_FranchiseTypesOutletFunctions_OutletFunctionID]
	FOREIGN KEY (OutletFunctionID)
	REFERENCES dbo.RoleTypes (RoleTypeID)	
