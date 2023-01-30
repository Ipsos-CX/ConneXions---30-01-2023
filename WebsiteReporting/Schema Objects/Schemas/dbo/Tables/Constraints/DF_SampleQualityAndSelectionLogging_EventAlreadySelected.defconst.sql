ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_EventAlreadySelected] 
   DEFAULT 0
   FOR EventAlreadySelected


