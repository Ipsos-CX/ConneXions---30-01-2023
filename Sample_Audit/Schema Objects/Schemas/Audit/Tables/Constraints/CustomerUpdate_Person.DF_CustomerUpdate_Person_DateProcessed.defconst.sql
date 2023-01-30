ALTER TABLE [Audit].[CustomerUpdate_Person]
   ADD CONSTRAINT [DF_CustomerUpdate_Person_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


