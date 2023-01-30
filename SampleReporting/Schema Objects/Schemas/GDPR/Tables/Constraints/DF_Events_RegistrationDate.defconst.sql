 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_RegistrationDate] 
   DEFAULT ''
   FOR [Registration Date]