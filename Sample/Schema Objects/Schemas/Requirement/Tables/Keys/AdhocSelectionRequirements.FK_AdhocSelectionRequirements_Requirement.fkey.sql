ALTER TABLE [Requirement].[AdhocSelectionRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionRequirements_Requirements] 
	FOREIGN KEY (RequirementID)
	REFERENCES Requirement.Requirements (RequirementID)

