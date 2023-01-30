﻿ALTER TABLE [Event].[EventPartyRoles]
    ADD CONSTRAINT [PK_EventPartyRoles] PRIMARY KEY CLUSTERED ([PartyID] ASC, [RoleTypeID] ASC, [EventID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

