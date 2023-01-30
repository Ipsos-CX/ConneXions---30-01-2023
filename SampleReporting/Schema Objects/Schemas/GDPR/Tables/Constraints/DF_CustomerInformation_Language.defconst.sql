ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_Language] 
   DEFAULT ''
   FOR [Language]
