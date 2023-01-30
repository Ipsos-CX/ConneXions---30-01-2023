CREATE PROCEDURE [SelectionOutput].[uspAdhocOnlineEmailContactDetails]

AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	------------------------------------------------------------------
	-- Update Email Contact Details 
	------------------------------------------------------------------
	
	-- Email Contact Details based on Language
	UPDATE O
	SET EmailSignator		=	ecd.EmailSignator,
		EmailSignatorTitle	=	ecd.EmailSignatorTitle,
		EmailContactText	=	ecd.EmailContactText,
		EmailCompanyDetails =	ecd.EmailCompanyDetails
	
	FROM SelectionOutput.AdhocSelection_FinalOutput O
	INNER JOIN ContactMechanism.Countries c ON c.CountryID = O.ccode
	INNER JOIN dbo.Markets m ON m.CountryID = c.CountryID
	INNER JOIN dbo.Languages l ON l.languageID = O.Lang
	INNER JOIN Event.vwEventTypes AS ET ON ET.EventTypeID = O.etype
	INNER JOIN SelectionOutput.OnlineEmailContactDetails ecd 
					ON  ecd.Brand = stype
					AND ecd.Market = m.Market
					AND ecd.Questionnaire = ET.EventCategory
					AND ecd.EmailLanguage = l.[Language]

	WHERE O.ITYPE = 'H'
	

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