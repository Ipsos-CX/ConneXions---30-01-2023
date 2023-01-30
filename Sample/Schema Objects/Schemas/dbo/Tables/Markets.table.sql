CREATE TABLE [dbo].[Markets]
(
	MarketID							INT NOT NULL IDENTITY(1,1), 
	Market  dbo.Country					NOT NULL,
	CountryID dbo.CountryID				NOT NULL,
	DealerTableEquivMarket				nvarchar(255) NULL,
	PartyMatchingMethodologyID			INT NOT NULL,
	RegionID							INT NOT NULL, 
	SMSOutputByLanguage					BIT NOT NULL,
	EventXDealerList					BIT NOT NULL,
	SMSOutputFileExtension				VARCHAR(50),
	AltRoadsideEmailMatching			BIT NOT NULL,
	SelectionOutput_NSCFlag				CHAR (1) NULL,
	IncSubNationalTerritoryInHierarchy  BIT NULL,
	ContactPreferencesModel				VARCHAR(50)  NOT NULL,				-- Either "Global" or "By Survey"
	ContactPreferencesPersist			BIT NOT NULL,
	AltRoadsideTelephoneMatching		BIT NOT NULL,
	AltSMSOutputFile					BIT NOT NULL, 
    FranchiseCountry					NVARCHAR(100) NULL, 
    FranchiseCountryType				NVARCHAR(10) NULL, 
    ExcludeEmployeeData					BIT NOT NULL,
	UseLatestName						BIT	NOT NULL,
	LegalGrounds                        INT NULL, -- TASK 600 29/09/21
    AnonymityQuestion                   INT NULL, -- TASK 600 29/09/21,
	MarketOutputTxt						NVARCHAR(255) NULL  -- TASK 764 20/01/2022
)
