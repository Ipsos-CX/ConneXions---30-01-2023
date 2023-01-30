ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_InvalidDateOfLastContact] 
   DEFAULT 0
   FOR InvalidDateOfLastContact


