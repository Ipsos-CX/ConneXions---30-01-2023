 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_InvoiceValue] 
   DEFAULT ''
   FOR [Invoice Value]
