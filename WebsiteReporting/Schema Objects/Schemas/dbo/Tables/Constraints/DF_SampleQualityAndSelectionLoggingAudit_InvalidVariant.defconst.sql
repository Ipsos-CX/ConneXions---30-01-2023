ALTER TABLE [dbo].[SampleQualityAndSelectionLoggingAudit]
   ADD CONSTRAINT [DF_SampleQualityAndSelectionLoggingAudit_InvalidVariant]
   DEFAULT 0
   FOR [InvalidVariant]


