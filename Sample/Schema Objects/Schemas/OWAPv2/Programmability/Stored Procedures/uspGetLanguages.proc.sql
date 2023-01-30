CREATE PROCEDURE [OWAPv2].[uspGetLanguages]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN
/*
Description
-----------

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			05-09-2016	Eddie Thomas	Created

*/
--Disable Counts
	SET NOCOUNT ON


--Return Languages result set
	SELECT	LanguageID,
			Language,
			ISOAlpha2,
			ISOAlpha3
	
	FROM	[dbo].Languages

	ORDER BY [Language]

	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END