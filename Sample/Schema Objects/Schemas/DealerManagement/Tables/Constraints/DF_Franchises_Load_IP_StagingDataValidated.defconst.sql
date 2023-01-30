ALTER TABLE [DealerManagement].[Franchises_Load]
   ADD CONSTRAINT [DF_Franchises_Load_IP_StagingDataValidated]
   DEFAULT 0
   FOR [IP_StagingDataValidated]