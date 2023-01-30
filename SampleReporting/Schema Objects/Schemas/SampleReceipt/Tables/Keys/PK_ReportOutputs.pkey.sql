﻿ALTER TABLE [SampleReceipt].[ReportOutputs]
    ADD CONSTRAINT [PK_ReportOutputs] PRIMARY KEY CLUSTERED (ReportOutputID ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);
