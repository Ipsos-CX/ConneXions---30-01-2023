 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_DealerCode] 
   DEFAULT ''
   FOR [Dealer Code]