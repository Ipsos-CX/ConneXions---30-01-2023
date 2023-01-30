ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_EventType] 
   DEFAULT ''
   FOR [Event Type]
