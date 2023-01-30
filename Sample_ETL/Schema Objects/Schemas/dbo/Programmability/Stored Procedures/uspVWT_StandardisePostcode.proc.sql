CREATE PROCEDURE dbo.uspVWT_StandardisePostcode
AS

/*
	Purpose:	Standardise any postcode values (Currently only required for Japan)
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspSTANDARDISEADDRESS_Postcode

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
 
 	CREATE TABLE #Postcode
	(
		VWTID INT,
		PostcodeOrig NVARCHAR(60)
	)

	INSERT INTO #Postcode
	(
		VWTID,
		PostcodeOrig
	)
	SELECT
		VWTID,
		Postcode
	FROM VWT
	WHERE CountryID = (SELECT CountryID FROM Lookup.vwCountries WHERE Country = 'Japan')
	AND ISNULL(Postcode, '') <> ''

	UPDATE V
	SET V.Postcode = CASE
				WHEN LEN(P.PostcodeOrig) = 7 THEN LEFT(P.PostcodeOrig, 3) + '-' + RIGHT(P.PostcodeOrig, 4)
				ELSE P.PostcodeOrig
			END
	FROM #Postcode P
	INNER JOIN dbo.VWT V ON V.VWTID = P.VWTID

	DROP TABLE #Postcode

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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH




