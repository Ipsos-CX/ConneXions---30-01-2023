CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_MarketQuestionnaire]
ON [dbo].[SampleQualityAndSelectionLogging] ([Market],[Questionnaire],[LoadedDate])
INCLUDE ([CaseID])
