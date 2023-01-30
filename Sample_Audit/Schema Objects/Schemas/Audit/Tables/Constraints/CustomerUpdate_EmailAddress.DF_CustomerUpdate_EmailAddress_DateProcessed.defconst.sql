ALTER TABLE [Audit].[CustomerUpdate_EmailAddress]
   ADD CONSTRAINT [DF_CustomerUpdate_EmailAddress_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


