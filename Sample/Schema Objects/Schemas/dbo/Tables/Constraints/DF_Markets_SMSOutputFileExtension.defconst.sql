ALTER TABLE [dbo].[Markets] 
ADD  CONSTRAINT [DF_Markets_SMSOutputFileExtension]  DEFAULT ('.csv') FOR [SMSOutputFileExtension]