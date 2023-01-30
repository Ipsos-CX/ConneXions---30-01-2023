CREATE TABLE [SampleReceipt].[FileSummary]
(
	ReportDate			DATETIME NOT NULL,
	MarketOrRegionFlag	CHAR(1) NOT NULL,
	MarketRegion		NVARCHAR(255) NOT NULL, 
	Questionnaire		NVARCHAR(255) NOT NULL, 
	AuditID				BIGINT NOT NULL, 
	Filename			VARCHAR(100) NOT NULL,
	FileLoadDate		DATETIME2 NOT NULL,
	FileRowCount		BIGINT,
	TotalRowsLoaded		BIGINT,
	RowsLoadedJaguar	BIGINT,
	RowsLoadedLandRover	BIGINT
)

