ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_FirstName] 
   DEFAULT ''
   FOR [First Name]