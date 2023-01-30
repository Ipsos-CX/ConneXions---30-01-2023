 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_CustomerContactStatus] 
   DEFAULT ''
   FOR [Customer Contact Status]
