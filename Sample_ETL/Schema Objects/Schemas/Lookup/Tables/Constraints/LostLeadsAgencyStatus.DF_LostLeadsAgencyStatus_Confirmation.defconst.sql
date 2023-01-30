ALTER TABLE [Lookup].[LostLeadsAgencyStatus]
   ADD CONSTRAINT [DF_LostLeadsAgencyStatus_Confirmation] 
   DEFAULT 1
   FOR Confirmation