ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_Region] 
   DEFAULT ''
   FOR [Region]
