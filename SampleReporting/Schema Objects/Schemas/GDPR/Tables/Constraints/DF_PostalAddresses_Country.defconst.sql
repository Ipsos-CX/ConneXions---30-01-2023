ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_Country] 
   DEFAULT ''
   FOR [Country]


