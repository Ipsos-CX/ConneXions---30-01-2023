ALTER TABLE [SelectionOutput].[Merged_SMS]
   ADD CONSTRAINT [DF_Merged_SMS_ReoutputIndicator] 
   DEFAULT 0
   FOR [ReoutputIndicator]


