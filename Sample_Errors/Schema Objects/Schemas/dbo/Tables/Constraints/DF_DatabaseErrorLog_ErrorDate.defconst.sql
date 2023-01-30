ALTER TABLE [dbo].[DatabaseErrorLog]
   ADD CONSTRAINT [DF_DatabaseErrorLog_ErrorDate] 
   DEFAULT GETDATE()
   FOR ErrorDate


