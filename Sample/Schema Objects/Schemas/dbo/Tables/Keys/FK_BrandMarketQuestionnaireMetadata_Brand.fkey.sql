ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireMetadata_Brand] 
	FOREIGN KEY (BrandID)
	REFERENCES Brands (BrandID)	

