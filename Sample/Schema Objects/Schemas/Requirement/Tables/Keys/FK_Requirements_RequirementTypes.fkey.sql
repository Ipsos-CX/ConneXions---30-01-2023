ALTER TABLE [Requirement].[Requirements]
    ADD CONSTRAINT [FK_Requirements_RequirementTypes] FOREIGN KEY ([RequirementTypeID]) 
    REFERENCES [Requirement].[RequirementTypes] ([RequirementTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

