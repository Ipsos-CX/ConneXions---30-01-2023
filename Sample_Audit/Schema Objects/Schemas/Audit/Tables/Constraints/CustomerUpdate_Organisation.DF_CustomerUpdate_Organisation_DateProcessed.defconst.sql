ALTER TABLE [Audit].[CustomerUpdate_Organisation]
   ADD CONSTRAINT [DF_CustomerUpdate_Organisation_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


