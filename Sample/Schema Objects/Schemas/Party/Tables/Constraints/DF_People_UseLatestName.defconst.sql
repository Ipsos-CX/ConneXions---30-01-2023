﻿ALTER TABLE [Party].[People]
	ADD CONSTRAINT [DF_People_UseLatestName]
	DEFAULT 0
	FOR [UseLatestName]
