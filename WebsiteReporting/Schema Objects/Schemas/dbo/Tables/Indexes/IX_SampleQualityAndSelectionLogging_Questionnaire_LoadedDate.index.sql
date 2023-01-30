CREATE NONCLUSTERED INDEX [IX_SampleQualityAndSelectionLogging_Questionnaire_LoadedDate] 
	ON [dbo].[SampleQualityAndSelectionLogging] ([Questionnaire],[LoadedDate]) 
	INCLUDE ([MatchedODSEventID])