﻿ALTER TABLE [Stage].[CXP_CRC]
	ADD CONSTRAINT [PK_CXP_CRC]
	PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);