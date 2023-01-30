CREATE TABLE [NWB].[RequestAlerts]
(
	RequestAlertID				INT IDENTITY(1,1) NOT NULL,
	NwbSampleUploadRequestKey	INT NOT NULL,
	AlertTypeID					INT NOT NULL,
	CreatedDate					DATETIME NOT NULL,
	EmailSentDate				DATETIME NULL,
	EmailRecipients				VARCHAR(255) NOT NULL,
	EmailCCRecipients			VARCHAR(255) NULL,
	EmailTitleText				VARCHAR(255) NOT NULL,
	EmailBodyText				VARCHAR(4000) NOT NULL
)
