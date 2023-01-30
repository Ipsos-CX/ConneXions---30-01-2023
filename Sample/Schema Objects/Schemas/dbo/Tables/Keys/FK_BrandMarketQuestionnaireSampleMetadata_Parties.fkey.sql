ALTER TABLE [dbo].[BrandMarketQuestionnaireSampleMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireSampleMetadata_Parties] 
	FOREIGN KEY (DealerCodeOriginatorPartyID)
	REFERENCES Party.Parties (PartyID)	

