CREATE PROCEDURE [OWAPv2].[uspGetDealerFunctions]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN

/*
Description
-----------
  Gets the valid "functions" parameter values used for the DealeDoAppointments proc


Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			15-09-2016	Chris Ross		Created
1.1			09-08-2017	Chris Ledger	Add Bodyshop UAT

*/


	--Disable Counts
	SET NOCOUNT ON

	-- OUtput the functions
	CREATE TABLE #Functions 
		(
		 DisplayOrder    INT, 
		 DisplayFunction VARCHAR(100), 
		 ReturnFunction  VARCHAR(100)
		 )

	INSERT INTO #Functions (DisplayOrder, DisplayFunction, ReturnFunction)
	VALUES (1, 'Sales', 'Sales'),
			(2, 'Aftersales', 'Aftersales'),
			(3, 'PreOwned', 'PreOwned'),
			(4, 'Bodyshop', 'Bodyshop'),
			(5, 'Both (Sales and AfterSales)', 'Both'),
			(6, 'All', 'All')

	SELECT * FROM #Functions
	ORDER BY DisplayOrder

	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END