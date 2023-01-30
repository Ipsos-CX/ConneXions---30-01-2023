ALTER TABLE [Requirement].[QuestionnaireAssociations]
    ADD CONSTRAINT [FK_QuestionnaireAssociations_QuestionnaireRequirements_From] FOREIGN KEY ([RequirementIDFrom]) 
    REFERENCES [Requirement].[QuestionnaireRequirements] ([RequirementID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

