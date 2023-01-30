ALTER TABLE [Requirement].[AdhocSelectionModelRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionModelRequirements_Requirements_MadeUpOf] 
	FOREIGN KEY (RequirementIDMadeUpOf)
	REFERENCES Requirement.Requirements (RequirementID)

