ALTER TABLE [Requirement].[SelectionRequirements]
    ADD CONSTRAINT [FK_SelectionRequirements_Requirements] FOREIGN KEY ([RequirementID]) REFERENCES [Requirement].[Requirements] ([RequirementID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

