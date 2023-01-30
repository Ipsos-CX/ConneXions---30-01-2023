CREATE TABLE [Party].[OrganisationAddressingPatterns] (
	[OrganisationAddressingPatternID]		INT	IDENTITY(1,1)				NOT NULL,
    [QuestionnaireRequirementID] dbo.RequirementID                      NOT NULL,
    [CountryID]                  [dbo].[CountryID]        NOT NULL,
    [LanguageID]                 dbo.LanguageID                 NULL,
    [Pattern]                    NVARCHAR (4000)          NULL,
    [AddressingTypeID]           [dbo].[AddressingTypeID] NULL
);

