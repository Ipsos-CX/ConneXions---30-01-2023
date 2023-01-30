ALTER TABLE [Audit].[CustomerUpdate_LostLeadModelOfInterest]
   ADD CONSTRAINT [DF_CustomerUpdate_LostLeadModelOfInterest_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


