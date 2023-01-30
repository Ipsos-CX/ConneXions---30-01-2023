ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_SecondLastName] 
   DEFAULT ''
   FOR [Second Last Name]