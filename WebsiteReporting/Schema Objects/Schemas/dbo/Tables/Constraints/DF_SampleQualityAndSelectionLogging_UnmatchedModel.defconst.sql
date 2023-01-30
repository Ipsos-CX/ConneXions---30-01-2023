ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_UnmatchedModel] 
   DEFAULT 0
   FOR UnmatchedModel


