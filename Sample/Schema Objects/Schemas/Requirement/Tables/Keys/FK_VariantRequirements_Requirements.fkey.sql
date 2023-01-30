ALTER TABLE [Requirement].[VariantRequirements]
	ADD CONSTRAINT [FK_VariantRequirements_Requirements] 
	FOREIGN KEY (RequirementID)
	REFERENCES Requirement.Requirements (RequirementID)	

