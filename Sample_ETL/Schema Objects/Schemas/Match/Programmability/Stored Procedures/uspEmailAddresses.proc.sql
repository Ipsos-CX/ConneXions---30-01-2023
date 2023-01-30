CREATE PROCEDURE [Match].[uspEmailAddresses]

AS

/*
	Purpose:	Match Email Addresses based on the exact email address string held in the Sample database
	
		Version			Date			Developer			Comment
LIVE	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_ElectronicAddresses
LIVE	1.1				07/08/2013		Chris Ross			Added in matching on Private Email address as well.
LIVE	1.2				01/12/2014		Chris Ross			BUG 10916 - Remove checksum match as single field so not required.
LIVE	1.3				11/02/2020		Chris Ledger		BUG 16936 - Trim leading/trailing spaces from email addresses.
LIVE	1.4				23/11/2021		Chris Ledger		TASK 701 - remove cyrillic characters from Russian email addresses.
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	-- V1.4 REMOVE CYRILLIC CHARACTERS
	UPDATE V
	SET V.EmailAddress = dbo.udfReplaceCyrillicCharacters(V.EmailAddress)
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON V.CountryID = C.CountryID
	WHERE C.Country = 'Russian Federation'


	-- V1.4 REMOVE CYRILLIC CHARACTERS
	UPDATE V
	SET V.PrivEmailAddress = dbo.udfReplaceCyrillicCharacters(V.PrivEmailAddress)
	FROM dbo.VWT V
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON V.CountryID = C.CountryID
	WHERE C.Country = 'Russian Federation'

	
	UPDATE V
	SET V.MatchedODSEmailAddressID = EA.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Match.vwEmailAddresses EA ON EA.EmailAddress = LTRIM(RTRIM(V.EmailAddress))			-- V1.3
	WHERE ISNULL(LTRIM(RTRIM(V.EmailAddress)), '') <> '' -- DON'T INCLUDE NULL OR BLANK EMAILS		-- V1.3

	
	UPDATE V																						-- V1.1
	SET V.MatchedODSPrivEmailAddressID = EA.ContactMechanismID
	FROM dbo.VWT V
	INNER JOIN Match.vwEmailAddresses EA ON EA.EmailAddress = LTRIM(RTRIM(V.PrivEmailAddress))		-- V1.3
	WHERE ISNULL(LTRIM(RTRIM(V.PrivEmailAddress)), '') <> '' -- DON'T INCLUDE NULL OR BLANK EMAILS	-- V1.3
	
	
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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
			
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH



