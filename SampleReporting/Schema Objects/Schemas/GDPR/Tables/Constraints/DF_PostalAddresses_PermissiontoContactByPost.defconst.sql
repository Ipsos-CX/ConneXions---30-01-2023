ALTER TABLE [GDPR].[PostalAddresses]
   ADD CONSTRAINT [DF_PostalAddresses_PermissiontoContactByPost] 
   DEFAULT ''
   FOR [Permission to Contact By Post?]