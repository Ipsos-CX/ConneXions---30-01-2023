CREATE PROCEDURE [Stage].[uspStandardise_LandRover_Portugal_Sales_VISTA]
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				15/05/2015		Eddie Thomas		Original Version
	1.1				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	SET LANGUAGE british;
	SET DATEFORMAT YMD;
	
	DECLARE @Market				VARCHAR(20) = 'Portugal',
			@DefaultlanguageId	INT			= 0,
			@DefaultCountryID	INT			= 0

	-- Convert RegistrationDate in DateTime data type format
	UPDATE	Stage.LandRover_Portugal_Sales_VISTA
	SET		ConvertedRegistrationDate = CONVERT( DATETIME, [Registration Date],120)		
	WHERE	ISDATE ( [Registration Date] ) = 1
	AND		LEN([Registration Date]) = 10

	-- Convert HandoverDate  in DateTime data type format
	UPDATE	Stage.LandRover_Portugal_Sales_VISTA
	SET		ConvertedHandoverDate = CONVERT( DATETIME, [Handover Date],120)
	WHERE	ISDATE ( [Handover Date] ) = 1
	AND		LEN([Handover Date]) = 10


	-- Convert DateOfBirth  in DateTime data type format
	UPDATE	Stage.LandRover_Portugal_Sales_VISTA
	SET		ConvertedDateOfBirth = CONVERT( DATETIME, [Date of Birth],120) 
	WHERE	ISDATE ([Date of Birth]) = 1
	AND		LEN([Date of Birth]) = 10
	
	--Set language
	SELECT	@DefaultlanguageId = DefaultLanguageID
	FROM	[$(SampleDB)].ContactMechanism.Countries 
	WHERE	Country = @Market
	 
	UPDATE		PSV
	SET			PreferredLanguageId =	CASE 
											WHEN LEN(LTRIM(RTRIM(ISNULL(PSV.[Preferred Language],'')))) > 0 THEN LA.LanguageID
											ELSE @DefaultlanguageId
										END					
	FROM		Stage.LandRover_Portugal_Sales_VISTA PSV	
	LEFT JOIN	[$(SampleDB)].dbo.Languages LA ON ltrim(rtrim(PSV.[Preferred Language])) = LA.Language



	--Set Country
	SELECT	@DefaultCountryID = CountryID
	FROM	[$(SampleDB)].ContactMechanism.Countries 
	WHERE	Country = @Market

	
	UPDATE		PSV
	SET			CountryID =	CASE 
								WHEN LEN(LTRIM(RTRIM(ISNULL(PSV.[Country],'')))) > 0 THEN CO.CountryID
								ELSE @DefaultCountryID
							END					
	FROM		Stage.LandRover_Portugal_Sales_VISTA PSV	
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries CO ON ltrim(rtrim(PSV.Country)) = CO.Country

	---------------------------------------------------------------------------------------------------------
	--Validate CountryID and PreferredLanguageId fields. Raise an error If necessary.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	Stage.LandRover_Portugal_Sales_VISTA
				WHERE	ISNULL(CountryID,0)	= 0	OR 
						ISNULL(PreferredLanguageId,0) =0
			)			 
			
			RAISERROR(	N'CountryID / PreferredLanguageId cannot equal zero (Stage.LandRover_Portugal_Sales_VISTA).', 
						16,
						1
					 )
	
	
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
		INTO [$(ErrorDB)].Stage.LandRover_Portugal_Sales_VISTA_' + @TimestampString + '
		FROM Stage.LandRover_Portugal_Sales_VISTA
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

