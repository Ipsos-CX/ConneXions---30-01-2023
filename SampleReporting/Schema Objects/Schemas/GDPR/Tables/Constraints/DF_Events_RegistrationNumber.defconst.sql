 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_RegistrationNumber] 
   DEFAULT ''
   FOR [Registration Number]
