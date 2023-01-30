CREATE TABLE [Audit].[Markets]
(
	MarketID						INT NOT NULL, 
	Market							dbo.Country NOT NULL,
	CountryID						dbo.CountryID NOT NULL,
	DealerTableEquivMarket			nvarchar(255) NULL,
	PartyMatchingMethodologyID		INT NOT NULL,
	RegionID						INT NOT NULL, 
	SMSOutputByLanguage				BIT NOT NULL,
	EventXDealerList				BIT NOT NULL,
	SMSOutputFileExtension			VARCHAR(50),
	AltRoadsideEmailMatching		BIT NOT NULL,
	SelectionOutput_NSCFlag			CHAR (1) NULL,
	IncSubNationalTerritoryInHierarchy  BIT NULL,
	ContactPreferencesModel			VARCHAR(50)   NULL,				-- Either "Global" or "By Survey"
	ContactPreferencesPersist		BIT NULL,
	AltRoadsideTelephoneMatching	BIT NOT NULL,
	AltSMSOutputFile				BIT NOT NULL, 
    FranchiseCountry				NVARCHAR(100) NULL, 
    FranchiseCountryType			NVARCHAR(10) NULL, 
    ExcludeEmployeeData				BIT NOT NULL,
	UseLatestName					BIT NOT NULL,

	AuditRecordType					VARCHAR(50),						-- Deleted or Inserted
	UpdateDate						DATETIME2 NOT NULL,
	UpdateBy						VARCHAR(255) NOT NULL
)
