ALTER TABLE [SampleReport].[GlobalReportDistinctEventSummary]
	ADD CONSTRAINT [PK_GlobalReportDistinctEventSummary]
	PRIMARY KEY (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire)