﻿ALTER TABLE [CRM].[CaseResponseStatuses]
    ADD CONSTRAINT [PK_CaseResponseStatuses] PRIMARY KEY CLUSTERED (CaseID ASC, EventID ASC, ResponseStatusID) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);


 