ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_Gender] 
   DEFAULT ''
   FOR [Gender]