ALTER TABLE [Requirement].[AdhocSelectionModelYearRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionModelYearRequirements_Requirements_PartOf] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.Requirements (RequirementID)	

