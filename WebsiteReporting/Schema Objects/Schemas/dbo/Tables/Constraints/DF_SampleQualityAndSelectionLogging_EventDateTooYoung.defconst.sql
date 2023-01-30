 ALTER TABLE [dbo].[SampleQualityAndSelectionLogging]
 ADD CONSTRAINT [DF_SampleQualityAndSelectionLogging_EventDateTooYoung] DEFAULT ((0)) FOR [EventDateTooYoung];