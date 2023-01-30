ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_InvalidOwnershipCycle] 
   DEFAULT 0
   FOR InvalidOwnershipCycle


