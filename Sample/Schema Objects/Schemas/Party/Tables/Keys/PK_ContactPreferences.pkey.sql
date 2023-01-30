﻿ALTER TABLE [Party].[ContactPreferences]
    ADD CONSTRAINT [PK_PartyContactPreferences] 
   
    PRIMARY KEY CLUSTERED ([PartyID] ASC) 
    
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

