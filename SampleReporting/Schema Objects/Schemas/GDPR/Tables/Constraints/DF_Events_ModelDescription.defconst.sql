 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_ModelDescription] 
   DEFAULT ''
   FOR [Model Description]