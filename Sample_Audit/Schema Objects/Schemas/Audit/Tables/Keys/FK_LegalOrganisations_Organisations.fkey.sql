ALTER TABLE [Audit].[LegalOrganisations]
    ADD CONSTRAINT [FK_LegalOrganisations_Organisations] FOREIGN KEY ([PartyID], [AuditItemID]) 
    REFERENCES [Audit].[Organisations] ([PartyID], [AuditItemID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

