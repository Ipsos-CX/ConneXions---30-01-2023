ALTER TABLE [Requirement].[AdhocSelectionModelRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionModelRequirement_Requirements_PartOf] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.Requirements (RequirementID)	

