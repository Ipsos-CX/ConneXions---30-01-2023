ALTER TABLE [Requirement].[RequirementRollups]
    ADD CONSTRAINT [FK_RequirementRollups_Requirements_MadeUpOf] FOREIGN KEY ([RequirementIDMadeUpOf]) 
    REFERENCES [Requirement].[Requirements] ([RequirementID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

