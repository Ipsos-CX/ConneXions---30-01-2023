ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_LastName] 
   DEFAULT ''
   FOR [Last Name]