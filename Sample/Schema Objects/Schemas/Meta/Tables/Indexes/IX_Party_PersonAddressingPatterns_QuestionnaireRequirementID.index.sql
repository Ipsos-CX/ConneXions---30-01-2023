CREATE NONCLUSTERED INDEX [IX_Party_PersonAddressingPatterns_QuestionnaireRequirementID] 
	ON [Party].[PersonAddressingPatterns]
	(
		[QuestionnaireRequirementID] ASC
	)
	INCLUDE ( 	[TitleID],
		[CountryID],
		[LanguageID],
		[GenderID],
		[DefaultAddressing],
		[AddressingTypeID])
