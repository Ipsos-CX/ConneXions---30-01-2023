ALTER TABLE [dbo].[MigrationErrorLog]
   ADD CONSTRAINT [DF_MigrationErrorLog_ErrorDateTime] 
   DEFAULT GETDATE()
   FOR ErrorDateTime


