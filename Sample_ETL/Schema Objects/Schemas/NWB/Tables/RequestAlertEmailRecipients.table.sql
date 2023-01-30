CREATE TABLE [NWB].[RequestAlertEmailRecipients]
(
	LocalServerName		NVARCHAR(512) NOT NULL,
	AlertTypeID			INT NOT NULL, 
	EmailRecipients		VARCHAR(255),
	EmailCCRecipients	VARCHAR(255)
)
