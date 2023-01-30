ALTER TABLE [Audit].[CustomerUpdate_PostalAddress]
   ADD CONSTRAINT [DF_CustomerUpdate_PostalAddress_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


