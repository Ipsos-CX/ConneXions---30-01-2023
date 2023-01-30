CREATE TABLE [SelectionOutput].[ReoutputCases]
(
	[ID]					[int] IDENTITY(1,1) NOT NULL,
	[CaseID]				[dbo].[CaseID] NOT NULL,
	[Brand]					[dbo].[OrganisationName] NOT NULL,
	[Market]				[dbo].[Country] NOT NULL,
	[Questionnaire]			[dbo].[Requirement] NOT NULL,
	[ContactMethodology]	VARCHAR(50)	NOT NULL
)
