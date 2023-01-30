ALTER TABLE [GDPR].[EmailAddresses]
   ADD CONSTRAINT [DF_EmailAddresses_EmailAddress] 
   DEFAULT ''
   FOR [Email Address]
