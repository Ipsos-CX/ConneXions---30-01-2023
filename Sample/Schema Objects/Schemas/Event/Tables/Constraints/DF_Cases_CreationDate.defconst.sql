ALTER TABLE [Event].[Cases]
   ADD CONSTRAINT [DF_Cases_CreationDate] 
   DEFAULT GETDATE()
   FOR CreationDate


