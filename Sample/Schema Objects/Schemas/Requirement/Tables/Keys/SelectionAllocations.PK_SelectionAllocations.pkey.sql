ALTER TABLE [Requirement].[SelectionAllocations]
	ADD CONSTRAINT [PK_SelectionAllocations]
	PRIMARY KEY (RequirementIDMadeUpOf, RequirementIDPartOf)