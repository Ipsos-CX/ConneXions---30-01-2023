CREATE TABLE [SampleReceipt].[EmailList]
(
	EmailListID			INT IDENTITY (1, 1) NOT NULL,
	EmailListName		VARCHAR(300) NOT NULL,
	Environment			VARCHAR(100) NOT NULL, 
	EmailAddressList	VARCHAR(2000) NOT NULL,
	EmailAddressListCC  VARCHAR(2000) NULL,
	Enabled				BIT NOT NULL
)

