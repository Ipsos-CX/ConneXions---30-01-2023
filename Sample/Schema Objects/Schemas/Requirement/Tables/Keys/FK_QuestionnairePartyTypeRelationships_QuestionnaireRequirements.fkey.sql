ALTER TABLE [Requirement].[QuestionnairePartyTypeRelationships]
    ADD CONSTRAINT [FK_QuestionnairePartyTypeRelationships_QuestionnaireRequirements] FOREIGN KEY ([RequirementID]) 
    REFERENCES [Requirement].[QuestionnaireRequirements] ([RequirementID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

