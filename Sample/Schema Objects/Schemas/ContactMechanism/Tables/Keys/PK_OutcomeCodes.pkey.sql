﻿ALTER TABLE [ContactMechanism].[OutcomeCodes]
    ADD CONSTRAINT [PK_OutcomeCodes] PRIMARY KEY CLUSTERED ([OutcomeCode] ASC, [OutcomeCodeTypeID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

