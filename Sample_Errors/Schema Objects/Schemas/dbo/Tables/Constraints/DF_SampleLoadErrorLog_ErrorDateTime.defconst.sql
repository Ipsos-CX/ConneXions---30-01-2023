ALTER TABLE [dbo].[SampleLoadErrorLog]
   ADD CONSTRAINT [DF_SampleLoadErrorLog_ErrorDateTime] 
   DEFAULT GETDATE()
   FOR ErrorDateTime


