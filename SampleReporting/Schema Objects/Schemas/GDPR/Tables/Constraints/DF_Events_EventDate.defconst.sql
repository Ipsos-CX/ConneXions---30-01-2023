ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_EventDate] 
   DEFAULT ''
   FOR [Event Date]
