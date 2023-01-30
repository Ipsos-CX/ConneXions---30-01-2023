ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_BirthDate] 
   DEFAULT ''
   FOR [Birth Date]
