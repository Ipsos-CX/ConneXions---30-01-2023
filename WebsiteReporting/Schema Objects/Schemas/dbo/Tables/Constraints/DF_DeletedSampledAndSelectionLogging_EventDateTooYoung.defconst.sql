ALTER TABLE [dbo].[DeletedSampledAndSelectionLogging]
    ADD CONSTRAINT [DF_DeletedSampledAndSelectionLogging_EventDateTooYoung] 
    DEFAULT ((0)) 
    FOR [EventDateTooYoung];



