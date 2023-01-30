﻿ALTER TABLE [dbo].[DW_JLRCSPDealers_History]
    ADD CONSTRAINT [PK_DW_JLRCSPDealers_History] PRIMARY KEY CLUSTERED ([id] ASC, [DateStamp] ASC, [State] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

