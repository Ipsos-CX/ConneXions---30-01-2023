CREATE PROCEDURE [Stage].[uspStandardise_Jaguar_Spain_Sales_VISTA]
AS

/*
	Purpose:	Convert the service date from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				14/05/2015		Eddie Thomas		Original Version
	1.1				05/12/2018		Chris Ledger		Copy Code from LIVE to SOLUTION
	1.2				10/01/2020		Chris Ledger		BUG 15372: Fix Hard coded reference to database
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

	DECLARE @Market				VARCHAR(20) = 'Spain',
			@DefaultlanguageId	INT			= 0,
			@DefaultCountryID	INT			= 0
	
	
	-- Convert RegistrationDate in DateTime data type format
	UPDATE	Stage.Jaguar_Spain_Sales_VISTA
	SET		ConvertedRegistrationDate = CONVERT( DATETIME, [Registration Date],120)		
	WHERE	ISDATE ( [Registration Date] ) = 1
	AND		LEN([Registration Date]) = 10

	-- Convert HandoverDate  in DateTime data type format
	UPDATE	Stage.Jaguar_Spain_Sales_VISTA
	SET		ConvertedHandoverDate = CONVERT( DATETIME, [Handover Date],120)
	WHERE	ISDATE ( [Handover Date] ) = 1
	AND		LEN([Handover Date]) = 10


	-- Convert DateOfBirth  in DateTime data type format
	UPDATE	Stage.Jaguar_Spain_Sales_VISTA
	SET		ConvertedDateOfBirth = CONVERT( DATETIME, [Date of Birth],120) 
	WHERE	ISDATE ([Date of Birth]) = 1
	AND		LEN([Date of Birth]) = 10
	
	--Pick up the defauult language defined for this market
	SELECT		DISTINCT @DefaultlanguageId = DefaultLanguageID
	FROM		[$(SampleDB)].ContactMechanism.Countries WHERE Country = @Market
	
	
	--Set language
	SELECT	@DefaultlanguageId = DefaultLanguageID
	FROM	[$(SampleDB)].ContactMechanism.Countries 
	WHERE	Country = @Market
	 
	UPDATE		SSV
	SET			PreferredLanguageId =	CASE 
											WHEN LEN(LTRIM(RTRIM(ISNULL(SSV.[Preferred Language],'')))) > 0 THEN LA.LanguageID
											ELSE @DefaultlanguageId
										END					
	FROM		Stage.Jaguar_Spain_Sales_VISTA SSV	
	LEFT JOIN	[$(SampleDB)].dbo.Languages LA ON ltrim(rtrim(SSV.[Preferred Language])) = LA.Language


	-- V1.1 Force Andorra to Spain	
	UPDATE Stage.Jaguar_Spain_Sales_VISTA
	SET Country = 'Spain'
	WHERE Country = 'Andorra'


	--Set Country
	SELECT	@DefaultCountryID = CountryID
	FROM	[$(SampleDB)].ContactMechanism.Countries 
	WHERE	Country = @Market

	
	UPDATE		SSV
	SET			CountryID =	CASE 
								WHEN LEN(LTRIM(RTRIM(ISNULL(SSV.[Country],'')))) > 0 THEN CO.CountryID
								ELSE @DefaultCountryID
							END					
	FROM		Stage.Jaguar_Spain_Sales_VISTA SSV	
	LEFT JOIN	[$(SampleDB)].ContactMechanism.Countries CO ON ltrim(rtrim(SSV.Country)) = CO.Country

	---------------------------------------------------------------------------------------------------------
	--Validate CountryID and PreferredLanguageId fields. Raise an error If necessary.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	Stage.Jaguar_Spain_Sales_VISTA 
				WHERE	ISNULL(CountryID,0)	= 0	OR 
						ISNULL(PreferredLanguageId,0) =0
			)			 
			
			RAISERROR(	N'CountryID / PreferredLanguageId cannot equal zero (Stage.Jaguar_Spain_Sales_VISTA).', 
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
		INTO [$(ErrorDB)].Stage.Jaguar_Spain_Sales_VISTA_' + @TimestampString + '
		FROM Stage.Jaguar_Spain_Sales_VISTA
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH

