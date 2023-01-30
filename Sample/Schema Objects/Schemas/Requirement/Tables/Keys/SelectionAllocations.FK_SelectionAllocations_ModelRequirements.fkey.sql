ALTER TABLE [Requirement].[SelectionAllocations]
	ADD CONSTRAINT [FK_SelectionAllocations_ModelRequirements] 
	FOREIGN KEY (RequirementIDMadeUpOf)
	REFERENCES Requirement.Requirements (RequirementID)	

