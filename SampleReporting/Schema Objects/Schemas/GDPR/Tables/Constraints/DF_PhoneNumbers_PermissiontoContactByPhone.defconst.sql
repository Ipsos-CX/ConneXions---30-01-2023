ALTER TABLE [GDPR].[PhoneNumbers]
   ADD CONSTRAINT [DF_PhoneNumbers_PermissiontoContactByPhone] 
   DEFAULT ''
   FOR [Permission to Contact By Phone?]
