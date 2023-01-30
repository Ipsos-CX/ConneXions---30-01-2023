CREATE PROCEDURE [OWAP].[uspNEWGetCountries]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN
/*
Description
-----------

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			07-09-2016	Eddie Thomas	Created

*/
--Disable Counts
	SET NOCOUNT ON


--Return Countries result set
	SELECT	CountryID,
			Country,
			ISOAlpha2,
			ISOAlpha3
	
	FROM	ContactMechanism.Countries

	ORDER BY Country

	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END