ALTER TABLE [Requirement].[SelectionAllocations]
	ADD CONSTRAINT [FK_SelectionAllocations_SelectionRequirements] 
	FOREIGN KEY (RequirementIDPartOf)
	REFERENCES Requirement.SelectionRequirements (RequirementID)	

