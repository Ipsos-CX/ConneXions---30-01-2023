ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_PostCode] 
   DEFAULT ''
   FOR [PostCode] 
