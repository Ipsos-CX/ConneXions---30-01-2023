ALTER TABLE [Requirement].[RequirementRollups]
    ADD CONSTRAINT [FK_RequirementRollups_Requirements_PartOf] FOREIGN KEY ([RequirementIDPartOf]) 
    REFERENCES [Requirement].[Requirements] ([RequirementID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

