ALTER TABLE [CustomerUpdate].[SMSBouncebacks]
   ADD CONSTRAINT [DF_CustomerUpdate_SMSBouncebacks_DateLoaded] 
   DEFAULT GETDATE()
   FOR DateLoaded


