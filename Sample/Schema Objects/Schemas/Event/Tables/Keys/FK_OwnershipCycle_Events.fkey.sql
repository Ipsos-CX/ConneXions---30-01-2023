ALTER TABLE [Event].[OwnershipCycle]
    ADD CONSTRAINT [FK_OwnershipCycle_Events] FOREIGN KEY ([EventID]) 
    REFERENCES [Event].[Events] ([EventID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION NOT FOR REPLICATION;

