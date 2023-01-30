 ALTER TABLE [GDPR].[Events]
   ADD CONSTRAINT [DF_Events_InvoiceNumber] 
   DEFAULT ''
   FOR [Invoice Number]
