 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_CustomerContactCreationDate] 
   DEFAULT ''
   FOR [Customer Contact Creation Date]
