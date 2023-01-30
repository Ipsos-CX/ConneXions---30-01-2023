ALTER TABLE [Audit].[CustomerUpdate_TelephoneNumber]
   ADD CONSTRAINT [DF_CustomerUpdate_TelephoneNumber_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


