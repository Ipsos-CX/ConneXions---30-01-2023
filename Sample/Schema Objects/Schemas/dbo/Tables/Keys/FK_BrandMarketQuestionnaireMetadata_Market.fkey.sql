ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireMetadata_Market] 
	FOREIGN KEY (MarketID)
	REFERENCES Markets (MarketID)	

