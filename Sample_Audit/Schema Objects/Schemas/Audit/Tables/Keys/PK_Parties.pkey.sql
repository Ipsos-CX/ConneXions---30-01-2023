ALTER TABLE [Audit].[Parties]
    ADD CONSTRAINT [PK_Parties] PRIMARY KEY CLUSTERED ([AuditItemID] ASC, [PartyID] ASC) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

