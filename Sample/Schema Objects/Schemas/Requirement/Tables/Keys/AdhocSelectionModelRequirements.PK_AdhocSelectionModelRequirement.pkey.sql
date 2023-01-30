ALTER TABLE [Requirement].[AdhocSelectionModelRequirements]
	ADD CONSTRAINT [PK_AdhocSelectionModelRequirement]
	PRIMARY KEY (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)