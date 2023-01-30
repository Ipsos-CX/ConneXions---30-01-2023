CREATE  PROCEDURE [dbo].[uspVWT_StandardiseTitles]

AS

/*
	Purpose:	Sets the TitleID in the VWT using the Title values in the operational database to match against	
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock	Created from [Prophet-ETL].dbo.uspSTANDARDISE_Titles
	1.1				20-12-2013		Chris Ross			BUG 8368	- Match on TitleVariation rather checksum of TitleVariation.
	1.2				11-11-2014		Peter Doyle			BUG 10006	- Attempting to load lareg amount of sample conatining no Title Information 
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	UPDATE V
	SET V.TitleID = TV.TitleID 	
	--SELECT TV.*
	FROM dbo.VWT V
	INNER JOIN (SELECT
		T.TitleID,
		TV.TitleVariation
	FROM [$(SampleDB)].Party.Titles T
	JOIN [$(SampleDB)].Party.TitleVariations TV ON T.TitleID = TV.TitleID) AS TV
	ON TitleVariation = ISNULL(V.Title,'')
	WHERE V.TitleID = 0
	
	

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