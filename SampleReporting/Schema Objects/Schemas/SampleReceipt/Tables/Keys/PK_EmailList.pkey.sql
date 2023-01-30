﻿ALTER TABLE [SampleReceipt].[EmailList]
    ADD CONSTRAINT [PK_EmailList] PRIMARY KEY CLUSTERED (EmailListID ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);
