ALTER TABLE [dbo].[Markets]
    ADD CONSTRAINT [DF_Markets_SMSOutputByLanguage] DEFAULT 0 FOR SMSOutputByLanguage;

