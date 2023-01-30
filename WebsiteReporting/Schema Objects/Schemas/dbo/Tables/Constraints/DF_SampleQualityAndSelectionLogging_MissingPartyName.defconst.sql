ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_MissingPartyName] 
   DEFAULT 0
   FOR MissingPartyName


