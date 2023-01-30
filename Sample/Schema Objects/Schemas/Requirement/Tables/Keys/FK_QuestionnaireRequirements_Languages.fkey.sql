ALTER TABLE [Requirement].[QuestionnaireRequirements]
    ADD CONSTRAINT [FK_QuestionnaireRequirements_Languages] FOREIGN KEY ([LanguageID]) REFERENCES [dbo].[Languages] ([LanguageID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

