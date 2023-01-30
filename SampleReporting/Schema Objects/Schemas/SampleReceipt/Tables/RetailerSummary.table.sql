CREATE TABLE [SampleReceipt].[RetailerSummary]
(
	ReportDate					DATETIME NOT NULL,
	Region						NVARCHAR(255) NOT NULL,
	Brand						NVARCHAR(510) NULL,
	Market						VARCHAR(200) NOT NULL,
	SubNationalTerritory		NVARCHAR(255) NULL,
	SubNationalRegion			NVARCHAR(255) NULL,
	Questionnaire				VARCHAR(255) NULL,
	OutletCode					NVARCHAR(20) NULL,
	OutletCode_GDD				NVARCHAR(20) NULL,
	Outlet						NVARCHAR(150) NULL,

	LatestFileReceivedDate		DATETIME NULL,
	DaysSinceSampleReceived		INT NULL,
	TotalFilesReceived			INT NULL,
	TotalRowsInLatestFiles		INT NULL,
	TotalEventsInLatestFiles	INT NULL,
	OldestEventDateInLatestFiles DATETIME NULL,
	LatestEventDateInLatestFiles DATETIME NULL,

	TotalRowsReceivedQTD		INT NULL,
	TotalEventsQTD				INT NULL,
	OldestEventDateQTD			DATETIME NULL,
	LatestEventDateQTD			DATETIME NULL,

	TotalRowsReceivedYTD		INT NULL,
	TotalEventsYTD				INT NULL,
	OldestEventDateYTD			DATETIME NULL,
	LatestEventDateYTD			DATETIME NULL,
	LatestFileDateForMarketRegion DATETIME NULL

)


