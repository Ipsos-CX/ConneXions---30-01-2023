CREATE PROCEDURE [dbo].[uspLogDatabaseError]
	@ErrorNumber INT,
	@ErrorSeverity INT,
	@ErrorState INT,
	@ErrorLocation NVARCHAR(500),
	@ErrorLine INT,
	@ErrorMessage NVARCHAR(2048)
AS

/*
	Purpose:	Write errors to log table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

INSERT INTO dbo.DatabaseErrorLog
(
	 ErrorDate
	,ErrorNumber
	,ErrorSeverity
	,ErrorState
	,ErrorLocation
	,ErrorLine
	,ErrorMessage
)
VALUES
(
	 GETDATE()
	,@ErrorNumber
	,@ErrorSeverity
	,@ErrorState
	,@ErrorLocation
	,@ErrorLine
	,@ErrorMessage
)