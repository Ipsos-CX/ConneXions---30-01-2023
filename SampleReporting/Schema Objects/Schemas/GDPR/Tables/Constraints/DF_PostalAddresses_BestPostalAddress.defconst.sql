ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_BestPostalAddress] 
   DEFAULT ''
   FOR [Best Postal Address?]