ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_PermissiontoContact] 
   DEFAULT ''
   FOR [Permission to Contact?]
