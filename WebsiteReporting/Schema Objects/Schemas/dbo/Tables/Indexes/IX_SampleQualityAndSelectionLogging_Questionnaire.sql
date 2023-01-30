CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_Questionnaire] 
	ON [dbo].[SampleQualityAndSelectionLogging]	([Questionnaire] ASC)
	INCLUDE ([MatchedODSEventID],[CaseID]) 