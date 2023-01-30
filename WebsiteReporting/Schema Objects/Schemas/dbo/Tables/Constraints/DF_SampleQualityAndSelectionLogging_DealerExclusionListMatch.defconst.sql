ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_DealerExclusionListMatch] 
   DEFAULT 0
   FOR DealerExclusionListMatch


