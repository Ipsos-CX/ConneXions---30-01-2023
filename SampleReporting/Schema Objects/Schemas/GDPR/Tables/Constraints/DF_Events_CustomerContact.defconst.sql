 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_CustomerContact] 
   DEFAULT ''
   FOR [Customer Contact?]
