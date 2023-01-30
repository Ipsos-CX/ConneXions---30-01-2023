﻿CREATE NONCLUSTERED INDEX [IX_Audit_PartyContactMechanisms_PartyIDContactMechanismID]
    ON [Audit].[PartyContactMechanisms]([PartyID] ASC, [ContactMechanismID] ASC) 
	INCLUDE ([RoleTypeID], [FromDate]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

