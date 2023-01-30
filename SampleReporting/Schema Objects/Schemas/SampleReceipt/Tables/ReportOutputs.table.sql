CREATE TABLE [SampleReceipt].[ReportOutputs]
(
	ReportOutputID		INT IDENTITY (1, 1) NOT NULL,
	MarketOrRegionFlag  CHAR(1) NOT NULL,
	MarketRegion		NVARCHAR(255) NOT NULL,
	Questionnaire		VARCHAR(255) NOT NULL,
	USDateFormat		BIT NOT NULL,
	TLVal2_DaysSinceSampleRec  INT NOT NULL,
	TLVal3_DaysSinceSampleRec  INT NOT NULL,
	Enabled				BIT NOT NULL
)
