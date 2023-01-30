 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_CustomerContactDescription] 
   DEFAULT ''
   FOR [Customer Contact Description]
