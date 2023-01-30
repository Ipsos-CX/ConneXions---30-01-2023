CREATE PROCEDURE Stage.uspStandardise_Jaguar_Spain_Service 
AS

/*
	Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock	Created from [Prophet-ETL].dbo.uspSTANDARDISE_STAGE_Landrover_Spain_Service_Dates
	1.1				2016-03-14		Chris Ledger		Change for default language
	1.2				2020-01-10		Chris Ledger		BUG 15372: Fix Hard coded reference to database
	1.3				2021-06-14		Ben King			TASK 499 - Language Code
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

SET LANGUAGE ENGLISH
SET DATEFORMAT DMY

BEGIN TRY

	DECLARE @Market				VARCHAR(20) = 'Spain',
			@DefaultlanguageId	INT			= 0,
			@DefaultCountryID	INT			= 0


	UPDATE Stage.Jaguar_Spain_Service
	SET VehiclePurchaseDateConverted = VehiclePurchaseDate
	WHERE ISDATE(VehiclePurchaseDate) = 1
	AND LEN(VehiclePurchaseDate) = 10
	
	UPDATE Stage.Jaguar_Spain_Service
	SET VehicleRegistrationDateConverted = VehicleRegistrationDate
	WHERE ISDATE(VehicleRegistrationDate) = 1
	AND LEN(VehicleRegistrationDate) = 10
	
	UPDATE Stage.Jaguar_Spain_Service
	SET VehicleDeliveryDateConverted = VehicleDeliveryDate
	WHERE ISDATE(VehicleDeliveryDate) = 1
	AND LEN(VehicleDeliveryDate) = 10
	
	UPDATE Stage.Jaguar_Spain_Service
	SET ServiceEventDateConverted = ServiceEventDate
	WHERE ISDATE(ServiceEventDate) = 1
	AND LEN(ServiceEventDate) = 10

	--BUG 12258 Pick up the defauult language defined for this market
	SELECT		DISTINCT @DefaultlanguageId = DefaultLanguageID
	FROM		[$(SampleDB)].ContactMechanism.Countries WHERE Country = @Market
	
	
	--BUG 12258 Set language
	SELECT	@DefaultlanguageId = DefaultLanguageID
	FROM	[$(SampleDB)].ContactMechanism.Countries 
	WHERE	Country = @Market
	 
	UPDATE		SSV
	SET			PreferredLanguageId =	CASE 
											WHEN LEN(LTRIM(RTRIM(ISNULL(SSV.[PreferredLanguage],'')))) > 0 THEN LA.LanguageID
											ELSE @DefaultlanguageId
										END,
				ConvertedPreferredLanguage = LA.Language					
	FROM		Stage.Jaguar_Spain_Service SSV	
	LEFT JOIN	[$(SampleDB)].dbo.Languages LA ON LTRIM(RTRIM(SSV.[PreferredLanguage])) = 
			CASE LA.Language
				WHEN 'English' THEN 'EN'
				WHEN 'German' THEN 'DE'
				WHEN 'Spain - Spanish' THEN 'ES' --V1.3
			END

	---------------------------------------------------------------------------------------------------------
	--Validate PreferredLanguageId fields. Raise an error If necessary.
	---------------------------------------------------------------------------------------------------------
	IF Exists( 
				SELECT	ID 
				FROM	Stage.Jaguar_Spain_Service 
				WHERE	ISNULL(PreferredLanguageId,0) =0
			)			 
			
			RAISERROR(	N'PreferredLanguageId cannot equal zero (Stage.Jaguar_Spain_Service).', 
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
		INTO [$(ErrorDB)].Stage.Jaguar_Spain_Service_' + @TimestampString + '
		FROM Stage.Jaguar_Spain_Service
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
