ALTER TABLE [dbo].[BrandMarketQuestionnaireMetadata]
	ADD CONSTRAINT [FK_BrandMarketQuestionnaireMetadata_ContactMethodologyTypes] 
	FOREIGN KEY (ContactMethodologyTypeID)
	REFERENCES SelectionOutput.ContactMethodologyTypes (ContactMethodologyTypeID)	

