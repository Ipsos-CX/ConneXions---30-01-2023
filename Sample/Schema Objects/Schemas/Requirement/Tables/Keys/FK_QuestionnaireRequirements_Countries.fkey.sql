ALTER TABLE [Requirement].[QuestionnaireRequirements]
    ADD CONSTRAINT [FK_QuestionnaireRequirements_Countries] 
    FOREIGN KEY ([CountryID]) 
    REFERENCES [ContactMechanism].[Countries] ([CountryID])

