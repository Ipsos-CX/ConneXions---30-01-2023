﻿ALTER TABLE [Party].[ContactPreferencesBySurvey]
    ADD CONSTRAINT [PK_PartyContactPreferencesBySurvey] 
   
    PRIMARY KEY CLUSTERED ([PartyID] ASC, [EventCategoryID] ASC) 
    
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

