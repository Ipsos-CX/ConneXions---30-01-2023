ALTER TABLE [Audit].[IndustryClassifications]
    ADD CONSTRAINT [FK_IndustryClassifications_PartyClassifications] FOREIGN KEY ([AuditItemID], [PartyTypeID], [PartyID], [FromDate]) 
    REFERENCES [Audit].[PartyClassifications] ([AuditItemID], [PartyTypeID], [PartyID], [FromDate]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

