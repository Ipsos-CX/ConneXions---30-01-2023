ALTER TABLE [Requirement].[QuestionnaireAssociations]
    ADD CONSTRAINT [FK_QuestionnaireAssociations_QuestionnaireRequirements_To] FOREIGN KEY ([RequirementIDTo]) 
    REFERENCES [Requirement].[QuestionnaireRequirements] ([RequirementID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

