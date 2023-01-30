CREATE PROCEDURE [Stage].[uspStandardise_LandRover_France_Sales_VISTA]
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				20/05/2013		Chris Ross		Original version

*/
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SET LANGUAGE british;
	SET DATEFORMAT ymd;
	
	-- Convert RegistrationDate in DateTime data type format
	UPDATE	Stage.LandRover_France_Sales_VISTA
	SET		ConvertedRegistrationDate = CONVERT( DATETIME, [Registration Date], 120)		
	WHERE	ISDATE ( [Registration Date] ) = 1
	AND		LEN([Registration Date]) = 10

	-- Convert HandoverDate  in DateTime data type format
	UPDATE	Stage.LandRover_France_Sales_VISTA
	SET		ConvertedHandoverDate = CONVERT( DATETIME, [Handover Date], 120)
	WHERE	ISDATE (  [Handover Date] ) = 1
	AND		LEN([Handover Date]) = 10


	---- Update table with combined birth dates built from Day, Month and Year columns
	--UPDATE  Stage.LandRover_France_Sales_VISTA
	--SET		CombinedDateOfBirth =
				--RIGHT('00' + CONVERT(VARCHAR(2), RTRIM(LTRIM([Date of Birth - DAY]))), 2)	+ '/' +   
				--RIGHT('00' + CONVERT(VARCHAR(2), RTRIM(LTRIM([Date of Birth - MONTH]))), 2)	+ '/' + 	
				--RIGHT('19' + CONVERT(VARCHAR(4), RTRIM(LTRIM([Date of Birth - YEAR]))), 4)  
	 --WHERE	ISNULL([Date of Birth - YEAR], '') <> '' 

	---- Convert Combined DOB if it is populated otherwise use the other "Date Of Birth" column
	--UPDATE	Stage.LandRover_France_Sales_VISTA
	--SET		ConvertedDateOfBirth = CONVERT( DATETIME, CombinedDateOfBirth)
	--WHERE	ISDATE (  CombinedDateOfBirth ) = 1
	--AND		LEN(CombinedDateOfBirth) = 10
	--AND		CombinedDateOfBirth IS NOT NULL


	-- Convert DateOfBirth  in DateTime data type format
	UPDATE	Stage.LandRover_France_Sales_VISTA
	SET		ConvertedDateOfBirth = CONVERT( DATETIME, [Date of Birth], 120) 
	WHERE	ISDATE (  [Date of Birth] ) = 1
	AND		LEN([Date of Birth]) = 10
	--AND		isnull(CombinedDateOfBirth, '') = ''


	----
	---- This to stop loading data where the date conversion has errors
	----
	--SELECT	CONVERT( DATETIME, [Registration Date] )
	--FROM	Stage.LandRover_France_Sales_VISTA
	--WHERE	ISDATE ( [Registration Date] ) = 0
	--AND		LEN([Registration Date]) = 10

	--SELECT	CONVERT( DATETIME, [Handover Date] )
	--FROM	Stage.LandRover_France_Sales_VISTA 
	--WHERE	ISDATE ( [Handover Date] ) = 0
	--AND		LEN([Handover Date]) = 10
	
	
	--SELECT	CONVERT( DATETIME, CombinedDateOfBirth )
	--FROM	Stage.LandRover_France_Sales_VISTA 
	--WHERE	ISDATE ( CombinedDateOfBirth ) = 0
	--AND		LEN(CombinedDateOfBirth) = 10
	--AND		CombinedDateOfBirth is not null
	
	--SELECT	CONVERT( DATETIME, [Date of Birth] )
	--FROM	Stage.LandRover_France_Sales_VISTA 
	--WHERE	ISDATE ( [Date of Birth] ) = 0
	--AND		LEN([Date of Birth]) = 10
	--AND		[Date of Birth] is null
	
	
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
		INTO [$(ErrorDB)].Stage.LandRover_France_Sales_VISTA' + @TimestampString + '
		FROM Stage.LandRover_France_Sales_VISTA
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

