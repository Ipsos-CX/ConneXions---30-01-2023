ALTER TABLE [GDPR].[EmailAddresses]
   ADD CONSTRAINT [DF_EmailAddresses_PermissiontoContactByEmail] 
   DEFAULT ''
   FOR [Permission to Contact By Email?]