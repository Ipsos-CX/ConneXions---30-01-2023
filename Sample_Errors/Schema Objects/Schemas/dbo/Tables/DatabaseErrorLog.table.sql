CREATE TABLE [dbo].[DatabaseErrorLog]
(
	ErrorLogID INT IDENTITY(1,1) NOT NULL, 
	ErrorDate DATETIME2 NOT NULL,
	ErrorNumber INT NULL,
	ErrorSeverity INT NULL,
	ErrorState INT NULL,
	ErrorLocation NVARCHAR(500) NULL,
	ErrorLine INT NULL,
	ErrorMessage NVARCHAR(2048) NULL
)
