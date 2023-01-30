CREATE TABLE [Party].[PersonAddressingPatterns] (
	[PersonAddressingPatternID]		INT	IDENTITY(1,1)				NOT NULL,
    [QuestionnaireRequirementID] dbo.RequirementID                      NOT NULL,
    [TitleID]                    dbo.TitleID                 NULL,
    [CountryID]                  [dbo].[CountryID]        NOT NULL,
    [LanguageID]                 dbo.LanguageID                 NULL,
    [GenderID]                   dbo.GenderID                  NULL,
    [Pattern]                    NVARCHAR (4000)          NULL,
    [DefaultAddressing]          BIT                      NULL,
    [AddressingTypeID]           [dbo].[AddressingTypeID] NULL
);

