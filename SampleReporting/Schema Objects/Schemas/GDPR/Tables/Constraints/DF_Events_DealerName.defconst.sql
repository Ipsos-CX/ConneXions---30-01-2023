 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_DealerName] 
   DEFAULT ''
   FOR [Dealer Name]
