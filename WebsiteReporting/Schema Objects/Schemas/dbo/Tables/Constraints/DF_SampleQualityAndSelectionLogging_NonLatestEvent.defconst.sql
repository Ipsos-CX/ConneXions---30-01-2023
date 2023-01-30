ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_NonLatestEvent] 
   DEFAULT 0
   FOR NonLatestEvent


