ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_Locality] 
   DEFAULT ''
   FOR [Locality]

