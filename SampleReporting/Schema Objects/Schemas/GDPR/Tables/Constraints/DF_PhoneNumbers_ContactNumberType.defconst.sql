ALTER TABLE [GDPR].[PhoneNumbers]
   ADD CONSTRAINT [DF_PhoneNumbers_ContactNumberType] 
   DEFAULT ''
   FOR [Contact Number Type]