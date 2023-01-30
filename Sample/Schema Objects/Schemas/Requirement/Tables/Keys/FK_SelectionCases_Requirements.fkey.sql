ALTER TABLE [Requirement].[SelectionCases]
    ADD CONSTRAINT [FK_SelectionCases_Requirements] FOREIGN KEY ([RequirementIDMadeUpOf]) REFERENCES [Requirement].[Requirements] ([RequirementID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

