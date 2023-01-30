ALTER TABLE [GDPR].[PhoneNumbers]
   ADD CONSTRAINT [DF_PhoneNumbers_ContactNumber] 
   DEFAULT ''
   FOR [Contact Number]