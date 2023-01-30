CREATE TABLE [dbo].[FileFailureReasons]
(
	FileFailureID INT IDENTITY(0,1) NOT NULL, 
	FileFailureReason VARCHAR(100) NOT NULL,
	FileFailureReasonShort VARCHAR(40) NULL
)
