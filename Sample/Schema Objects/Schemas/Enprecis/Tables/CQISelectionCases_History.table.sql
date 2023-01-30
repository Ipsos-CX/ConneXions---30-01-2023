CREATE TABLE [Enprecis].[CQISelectionCases_History](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[CaseID] [dbo].[CaseID] NOT NULL,
	[CQIFileName] [nvarchar](100) NOT NULL,
	[DateLoaded] [datetime] NULL,
)
