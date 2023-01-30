ALTER TABLE [SampleReport].[Base] 
	ADD  CONSTRAINT [df_SampleReport_Base_EventDateTooYoung]  
	DEFAULT (0) FOR [EventDateTooYoung]

