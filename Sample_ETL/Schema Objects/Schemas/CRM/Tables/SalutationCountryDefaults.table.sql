CREATE TABLE [CRM].[SalutationCountryDefaults](
	[SalutationCountryDefaultID] [int] IDENTITY(1,1) NOT NULL,
	[CountryISOAlpha2]  CHAR(2) NOT NULL,
	[CalcTitle]			BIT NOT NULL DEFAULT 0 ,
	[CalcNamePrefix]	BIT NOT NULL DEFAULT 0 ,
	[CalcNonAccTitle]	BIT NOT NULL DEFAULT 0 , 
	[UsePreferredLastName] BIT NOT NULL DEFAULT 0 ,
	[DefaultSalutation]  NVARCHAR(510) NOT NULL, 
	[Enabled]			 BIT NOT NULL DEFAULT 0
) ON [PRIMARY]