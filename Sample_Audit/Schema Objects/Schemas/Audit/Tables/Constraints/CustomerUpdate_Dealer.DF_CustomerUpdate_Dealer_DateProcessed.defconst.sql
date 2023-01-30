ALTER TABLE [Audit].[CustomerUpdate_Dealer]
   ADD CONSTRAINT [DF_CustomerUpdate_Dealer_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


