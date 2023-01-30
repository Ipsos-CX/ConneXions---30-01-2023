
--TASK 691
CREATE TABLE [SampleReport].[DataFeedCQI](
	[Market] [varchar](200) NOT NULL,
	[Brand] [nvarchar](510) NOT NULL,
	[Questionnaire] [varchar](255) NOT NULL,
	[Requirement] [varchar](255) NOT NULL,
	[SelectionDate] [date] NULL,
	[CaseID] [int] NOT NULL,
	[SaleDate] [date] NULL,
	[Week] [int] NULL,
	[Week Starting] [date] NULL,
	[DATA] [int] NOT NULL
) ON [PRIMARY]
GO

