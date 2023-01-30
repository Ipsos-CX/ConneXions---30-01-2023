CREATE TABLE [NWB].[RequestAlertTypes]
(
	AlertTypeID			INT IDENTITY(1,1)  NOT NULL,
	AlertType			VARCHAR(100) NOT NULL,
	AlertTimePeriodMins	INT NULL,
	EmailTitleText		VARCHAR(255) NOT NULL,
	EmailBodyText		VARCHAR(4000) NOT NULL
)
