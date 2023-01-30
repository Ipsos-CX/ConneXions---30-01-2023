ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_MiddleName] 
   DEFAULT ''
   FOR [Middle Name]