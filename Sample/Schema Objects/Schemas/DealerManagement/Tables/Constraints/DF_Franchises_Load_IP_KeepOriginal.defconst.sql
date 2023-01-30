ALTER TABLE [DealerManagement].[Franchises_Load]
   ADD CONSTRAINT [DF_Franchises_Load_IP_KeepOriginal]
   DEFAULT 0
   FOR [IP_KeepOriginal]