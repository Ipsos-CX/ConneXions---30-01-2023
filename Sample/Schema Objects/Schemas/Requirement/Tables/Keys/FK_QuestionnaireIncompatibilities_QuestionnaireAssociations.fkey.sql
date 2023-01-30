ALTER TABLE [Requirement].[QuestionnaireIncompatibilities]
    ADD CONSTRAINT [FK_QuestionnaireIncompatibilities_QuestionnaireAssociations] FOREIGN KEY ([RequirementIDFrom], [RequirementIDTo], [FromDate]) 
    REFERENCES [Requirement].[QuestionnaireAssociations] ([RequirementIDFrom], [RequirementIDTo], [FromDate]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

