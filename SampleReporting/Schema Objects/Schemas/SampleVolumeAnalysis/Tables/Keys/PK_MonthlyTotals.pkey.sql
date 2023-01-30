ALTER TABLE [SampleVolumeAnalysis].[MonthlyTotals]
    ADD CONSTRAINT [PK_MonthlyTotals] PRIMARY KEY CLUSTERED ([Market] ASC, [Questionnaire] ASC, [Brand] ASC, [ReportYear] ASC, [ReportMonth] ASC) 

