CREATE TABLE [Audit].[CaseLostLeads_Outputs]
(
	AuditItemID			BIGINT NOT NULL,
	
	EventID				BIGINT NOT NULL,
	CaseID				BIGINT,
	LostLeadAuditItemID	BIGINT, 
	LostLeadStatusID	INT NOT NULL,
	
	ValidationFailed	BIT,
	ValidationFailReasons VARCHAR(2000),
	
	RegionCode			NVARCHAR(8),
	MarketCode			NVARCHAR(8),
	CountryCode			NVARCHAR(3),
	SourceSystemLeadID	NVARCHAR(60),
	SequenceID			NVARCHAR(5),
	Brand				NVARCHAR(10),
	Nameplate			NVARCHAR(30),
	LeadOrigin			NVARCHAR(3),
	RetailerPAGNumber	NVARCHAR(10),
	RetailerCICode		NVARCHAR(20),
	RetailerBrand		NVARCHAR(20),
	LeadStatus			NVARCHAR(2),
	LeadStartTimestamp	NVARCHAR(14),
	LeadLostTimestamp	NVARCHAR(14),
	PassedToLLAFlag		NVARCHAR(1),
	PassedToLLATimestamp NVARCHAR(14),
	LostLeadAgency		NVARCHAR(5),
	ReasonsCode			NVARCHAR(50),
	ResurrectedFlag		NVARCHAR(1),
	LastUpdatedByLLA	NVARCHAR(14),
	BoughtElsewhereCompetitorFlag NVARCHAR(1),
	BoughtElsewhereJLRFlag	NVARCHAR(1),
	ContactedByGfKFlag	NVARCHAR(1),
	VehicleLostBrand	NVARCHAR(50),
	VehicleLostModelRange NVARCHAR(50),
	VehicleSaleType		NVARCHAR(4),
	
	OutputDate			DATETIME2  NULL,
	AllLostLeadStatuses VARCHAR(50) NULL
);


