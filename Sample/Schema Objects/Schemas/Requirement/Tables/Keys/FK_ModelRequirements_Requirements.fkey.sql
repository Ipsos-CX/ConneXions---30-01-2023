ALTER TABLE [Requirement].[ModelRequirements]
	ADD CONSTRAINT [FK_ModelRequirements_Requirements] 
	FOREIGN KEY (RequirementID)
	REFERENCES Requirement.Requirements (RequirementID)	

