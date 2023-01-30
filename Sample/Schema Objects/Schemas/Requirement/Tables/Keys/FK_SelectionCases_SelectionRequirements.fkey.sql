ALTER TABLE [Requirement].[SelectionCases]
    ADD CONSTRAINT [FK_SelectionCases_SelectionRequirements] FOREIGN KEY ([RequirementIDPartOf]) REFERENCES [Requirement].[SelectionRequirements] ([RequirementID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

