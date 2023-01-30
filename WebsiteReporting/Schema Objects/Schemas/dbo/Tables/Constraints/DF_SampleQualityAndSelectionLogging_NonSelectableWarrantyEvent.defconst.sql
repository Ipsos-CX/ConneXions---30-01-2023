ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_NonSelectableWarrantyEvent]
   DEFAULT 0
   FOR [NonSelectableWarrantyEvent]


