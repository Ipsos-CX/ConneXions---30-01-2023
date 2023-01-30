﻿ALTER TABLE [Audit].[EmployeeRelationships]
    ADD CONSTRAINT [PK_EmployeeRelationships] 
    PRIMARY KEY CLUSTERED ([AuditItemID] ASC, [PartyIDFrom] ASC, [PartyIDTo] ASC, [RoleTypeIDFrom] ASC, [RoleTypeIDTo] ASC, [EmployeeIdentifier] ASC) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

