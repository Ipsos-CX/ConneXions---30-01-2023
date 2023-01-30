ALTER TABLE [ContactMechanism].[Countries]
	ADD CONSTRAINT [FK_Countries_Languages] 
	FOREIGN KEY (DefaultLanguageID)
	REFERENCES dbo.Languages (LanguageID)	

