ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingLanguage] 
   DEFAULT 0
   FOR MissingLanguage


