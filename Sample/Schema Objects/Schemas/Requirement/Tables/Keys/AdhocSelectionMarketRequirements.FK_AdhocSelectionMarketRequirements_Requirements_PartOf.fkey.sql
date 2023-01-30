ALTER TABLE [Requirement].[AdhocSelectionMarketRequirements]
	ADD CONSTRAINT [FK_AdhocSelectionMarketRequirements_Requirements_PartOf] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.Requirements (RequirementID)	

