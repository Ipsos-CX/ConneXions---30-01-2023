﻿ALTER TABLE [Audit].[IndustryClassifications]
    ADD CONSTRAINT [PK_IndustryClassifications] PRIMARY KEY CLUSTERED ([AuditItemID] ASC, [PartyTypeID] ASC, [PartyExclusionCategoryID] ASC, [PartyID] ASC, [FromDate] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

