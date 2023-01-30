ALTER TABLE [Requirement].[SelectionAllocations]
	ADD CONSTRAINT [FK_SelectionAllocations_RequirementRollups] 
	FOREIGN KEY (RequirementIDMadeUpOf, RequirementIDPartOf)
	REFERENCES Requirement.RequirementRollups (RequirementIDMadeUpOf, RequirementIDPartOf)	

