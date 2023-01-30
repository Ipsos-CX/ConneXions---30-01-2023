﻿ALTER TABLE [SelectionOutput].[CATIAvailableLanguages]
	ADD CONSTRAINT [PK_CATIAvailableLanguages]
   PRIMARY KEY CLUSTERED (
							[Brand]			ASC,
							[Market]		ASC,
							[Questionnaire] ASC,
							[LanguageID]	ASC
						 ) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);