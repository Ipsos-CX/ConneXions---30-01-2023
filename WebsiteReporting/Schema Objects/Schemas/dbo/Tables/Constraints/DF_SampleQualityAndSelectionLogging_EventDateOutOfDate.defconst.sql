ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_EventDateOutOfDate] 
   DEFAULT 0
   FOR EventDateOutOfDate


