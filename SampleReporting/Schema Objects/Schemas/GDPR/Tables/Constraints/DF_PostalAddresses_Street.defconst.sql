ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_Street] 
   DEFAULT ''
   FOR [Street]

