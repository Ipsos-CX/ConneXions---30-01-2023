CREATE PROCEDURE [OWAPv2].[uspGetBrands]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN

/*
Description
-----------
  Gets the Brands for lookup


Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			16-09-2016	Chris Ross		Created

*/


	--Disable Counts
	SET NOCOUNT ON

	SELECT * FROM dbo.Brands
	ORDER BY Brand

	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END