ALTER TABLE [Audit].[CustomerUpdate_RegistrationNumber]
   ADD CONSTRAINT [DF_CustomerUpdate_RegistrationNumber_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


