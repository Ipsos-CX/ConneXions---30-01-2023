CREATE TRIGGER Party.TR_I_vwDA_PartyLanguages ON Party.vwDA_PartyLanguages
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_PartyLanguages
				All rows in VWT containing Language information should be inserted into this view 
				All rows are written to the Audit.PartyLanguages table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_PartyLanguages.TR_I_vwDA_vwDA_PartyLanguages

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		--THE INSERTED LANGUAGE IS NOT NEW FOR THE PARTY, RE-ACTIVATE THE EXISTING RECORD
		
		--SELECT * 
		UPDATE PL
		SET PreferredFlag = 1
		FROM INSERTED I
		INNER JOIN Party.Parties		P	ON P.PartyID		= I.PartyID
		INNER JOIN Party.PartyLanguages PL	ON	PL.LanguageID	= I.LanguageID
												AND PL.PartyID	= I.PartyID
		WHERE PL.PreferredFlag =0 



		--MAKE SURE THE PREFERRED FLAG IS DE-ACTIVATED FOR OTHER RECORDS 
		--THAT RELATE TO THE PARTY'S WE'RE UPDATING
		
		--SELECT * 
		UPDATE PL
		SET PreferredFlag = 0
		FROM INSERTED I
		
		INNER JOIN Party.Parties		P	ON P.PartyID		= I.PartyID
		INNER JOIN Party.PartyLanguages PL	ON	PL.PartyID	= I.PartyID
		WHERE PL.LanguageID <> I.LanguageID

		-- INSERT ALL PartyLanagues THAT DON'T ALREADY EXIST
		INSERT INTO Party.PartyLanguages
		(
			PartyID, 
			LanguageID, 
			PreferredFlag
		)
		SELECT DISTINCT
		I.PartyID, 
		I.LanguageID, 
		I.PreferredFlag
		FROM INSERTED I
		INNER JOIN Party.Parties P ON P.PartyID = I.PartyID
		LEFT JOIN Party.PartyLanguages PL ON PL.LanguageID = I.LanguageID
										AND PL.PartyID = I.PartyID
		WHERE PL.LanguageID IS NULL
		ORDER BY I.PartyID, I.LanguageID

		-- INSERT ALL ROWS INTO AUDIT
		INSERT INTO [$(AuditDB)].Audit.PartyLanguages
		(
			AuditItemID,
			PartyID, 
			LanguageID, 
			FromDate, 		
			ThroughDate, 
			PreferredFlag
		)
		SELECT DISTINCT
			I.AuditItemID,
			I.PartyID, 
			I.LanguageID, 
			I.FromDate,  
			I.ThroughDate, 
			I.PreferredFlag
		FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.PartyLanguages APL ON APL.AuditItemID = I.AuditItemID
														AND APL.PartyID = I.PartyID
		WHERE APL.AuditItemID IS NULL
		ORDER BY I.AuditItemID

	COMMIT TRAN

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
	











