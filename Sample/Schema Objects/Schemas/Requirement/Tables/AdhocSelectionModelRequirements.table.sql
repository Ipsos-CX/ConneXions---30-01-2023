CREATE TABLE [Requirement].[AdhocSelectionModelRequirements]
(
	[RequirementIDMadeUpOf] [dbo].[RequirementID] NOT NULL,
	[RequirementIDPartOf] [dbo].[RequirementID] NOT NULL,
	[FromDate] [datetime2](7) NOT NULL,
	[ThroughDate] [datetime2](7) NULL
)
