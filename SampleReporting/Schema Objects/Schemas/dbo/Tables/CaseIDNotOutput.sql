CREATE TABLE [dbo].[CaseIDNotOutput]
(
	[ReportDate] datetime NOT NULL,
	[CaseID]          BIGINT   NOT NULL,
	[Brand]           VARCHAR (100) NULL,
	[Market]          VARCHAR (100) NULL,
	[Questionnaire]   VARCHAR (100) NULL,
	[CaseCreationDate] DATETIME2 (7) NULL,
	[CaseIDLang]      VARCHAR (100) NULL
)
 