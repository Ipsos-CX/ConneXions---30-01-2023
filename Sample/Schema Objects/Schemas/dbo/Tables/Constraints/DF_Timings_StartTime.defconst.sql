ALTER TABLE [dbo].[Timings]
   ADD CONSTRAINT [DF_Timings_StartTime] 
   DEFAULT (getdate())
   FOR  [StartTime]


