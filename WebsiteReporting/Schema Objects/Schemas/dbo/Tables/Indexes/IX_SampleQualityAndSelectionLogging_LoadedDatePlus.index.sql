CREATE INDEX [IX_SampleQualityAndSelectionLogging_LoadedDatePlus]
    ON [dbo].[SampleQualityAndSelectionLogging]
	(LoadedDate)
	INCLUDE(CaseID, Brand, Market, Questionnaire)


