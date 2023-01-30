CREATE INDEX [IX_IndustryClassifications_PartyID] 
	ON [Party].[IndustryClassifications] ([PartyID]) 
	INCLUDE ([PartyExclusionCategoryID])