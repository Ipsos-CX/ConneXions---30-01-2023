CREATE PROCEDURE [CustomerUpdate].[uspExtraVehicleFeed_Standardise]

AS

/*
	Purpose:		Convert the supplied dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment																	Status
	1.0				2017-04-21		Chris Ledger		Created from [Sample_ETL].dbo.uspStandardise_Global_Sales				LIVE
	1.1				2017-08-23		Chris Ledger		BUG 14189 - Remove convert on SoldDateOrig and WarrantyStartDateOrig	DEPLOYED LIVE: CL 2017-08-25
	1.2				2021-03-29		Chris Ledger		Change formatting of ProductionMonthOrig
	1.3				2021-05-17		Chris Ledger		Change formatting of ProductionDateOrig from 103 = dd/mm/yyyy to 126 = YYYY-MM-DD
	1.4				2021-05-24		Chris Ledger		Reset formatting of ProductionDateOrig to 103 = dd/mm/yyyy
	1.5             2021-10-05      Ben King            TASK 633 - Fix EVF feed issue - concatenated data in last column


*/

DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

SET LANGUAGE ENGLISH
BEGIN TRY

	---------------------------------------------------------------------------------------------------------
	-- Convert ProductionDateOrig Date  
	---------------------------------------------------------------------------------------------------------
	UPDATE CustomerUpdate.ExtraVehicleFeed
	SET ProductionDate = CONVERT(DATETIME, ProductionDateOrig, 103)		-- V1.1	V1.3	V1.4
	WHERE NULLIF(ProductionDateOrig, '') IS NOT NULL
	---------------------------------------------------------------------------------------------------------	

	
	---------------------------------------------------------------------------------------------------------
	-- Convert ProductionMonthOrig Date  
	---------------------------------------------------------------------------------------------------------
	UPDATE CustomerUpdate.ExtraVehicleFeed
	SET ProductionMonth = CONVERT(DATETIME, SUBSTRING(ProductionMonthOrig, 1, 4) + '-' + SUBSTRING(ProductionMonthOrig, 5, 6) + '-01', 121)
	WHERE NULLIF(ProductionMonthOrig, '') IS NOT NULL
	---------------------------------------------------------------------------------------------------------


	---------------------------------------------------------------------------------------------------------
	-- Convert ModelYear
	---------------------------------------------------------------------------------------------------------
	UPDATE CustomerUpdate.ExtraVehicleFeed
	SET	ModelYearOrig = NULL
	WHERE LEN(ModelYearOrig) = 0

	UPDATE CustomerUpdate.ExtraVehicleFeed
	SET	ModelYear = CONVERT(INT, ModelYearOrig)
	WHERE NULLIF(ModelYearOrig, '') IS NOT NULL
	---------------------------------------------------------------------------------------------------------
	
	--V1.5
	IF EXISTS
			( 
				SELECT TOP 100 *, CHARINDEX(',',Engine), LEFT(Engine, CHARINDEX(',',Engine)-1)
				FROM CustomerUpdate.ExtraVehicleFeed
				WHERE CHARINDEX(',',Engine) > 0
			)			 
	BEGIN
				UPDATE C
				SET C.Engine = LEFT(Engine, CHARINDEX(',',Engine)-1)
				FROM CustomerUpdate.ExtraVehicleFeed C
	END


END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.ExtraVehicleFeed_' + @TimestampString + '
		FROM CustomerUpdate.ExtraVehicleFeed
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH