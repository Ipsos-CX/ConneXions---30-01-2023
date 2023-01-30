ALTER TABLE [SampleReport].[SummaryResponses]
   ADD CONSTRAINT [DF_SummaryResponses_EventsLoaded] 
   DEFAULT 0
   FOR [EventsLoaded]


