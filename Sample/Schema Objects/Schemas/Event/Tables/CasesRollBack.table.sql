CREATE TABLE [Event].[CasesRollBack]
(
	[CaseID] INT NOT NULL,
	[SelectionRequirementID] INT NOT NULL,
	[ProcessedDate] [datetime] NULL
		CONSTRAINT DFT_ContactPreferencesOverride_Date DEFAULT GETDATE()
)