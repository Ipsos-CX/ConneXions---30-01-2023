ALTER TABLE [GDPR].[EmailAddresses]
   ADD CONSTRAINT [DF_EmailAddresses_BestEmailAddress] 
   DEFAULT ''
   FOR [Best Email Address?]
