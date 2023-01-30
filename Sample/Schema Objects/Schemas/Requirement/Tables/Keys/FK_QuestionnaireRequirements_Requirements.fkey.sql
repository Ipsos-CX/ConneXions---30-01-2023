ALTER TABLE [Requirement].[QuestionnaireRequirements]
    ADD CONSTRAINT [FK_QuestionnaireRequirements_Requirements] 
    FOREIGN KEY ([RequirementID]) 
    REFERENCES [Requirement].[Requirements] ([RequirementID])

