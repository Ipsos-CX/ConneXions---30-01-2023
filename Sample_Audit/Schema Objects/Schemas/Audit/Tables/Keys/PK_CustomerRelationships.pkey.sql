ALTER TABLE [Audit].[CustomerRelationships]
    ADD CONSTRAINT [PK_CustomerRelationships] 
    PRIMARY KEY CLUSTERED ([AuditItemID] ASC, [PartyIDFrom] ASC, [PartyIDTo] ASC, [RoleTypeIDFrom] ASC, [RoleTypeIDTo] ASC, [CustomerIdentifier] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

