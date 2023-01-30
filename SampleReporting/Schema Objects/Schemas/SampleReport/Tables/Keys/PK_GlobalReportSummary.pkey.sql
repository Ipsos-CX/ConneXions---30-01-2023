ALTER TABLE [SampleReport].[GlobalReportSummary]
	ADD CONSTRAINT [PK_GlobalReportSummary]
	PRIMARY KEY (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire)