CREATE PROCEDURE [dbo].[uspRunPreSelectionFlags]
	@QuestionnaireRequirementID [dbo].[RequirementID]

AS
/*
	Purpose: Run same [Selection].[uspRunSelection] logic on all records regardless of if they make it into seleciton
	         pool.
		
	Version			Date			Developer			Comment
	1.0				20200123	    Ben King  		    BUG 16767 - NEW PRE-CHECK MIRROR'S SP [Selection].[uspRunSelection]
	
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

		-- DECLARE SELECTION VARIABLES
		DECLARE @EventCategoryID INT
		DECLARE @UpdateSelectionLogging BIT 
		DECLARE @ValidateAFRLCodes INT	
		DECLARE @UseLatestEmailTable INT
		DECLARE @MCQISurvey BIT  	

		
		SELECT
			 @EventCategoryID = (SELECT EventCategoryID FROM Sample.Event.EventCategories WHERE EventCategory = B.Questionnaire)
			,@UpdateSelectionLogging = B.UpdateSelectionLogging
			,@ValidateAFRLCodes = QR.ValidateAFRLCodes
			,@UseLatestEmailTable = QR.UseLatestEmailTable
			,@MCQISurvey	= CASE	WHEN SUBSTRING(R.Requirement,1,4) = 'MCQI' THEN 1
									ELSE 0 END	
		FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata B
		INNER JOIN [$(SampleDB)].Requirement.QuestionnaireRequirements QR ON QR.RequirementID = B.QuestionnaireRequirementID
		INNER JOIN [$(SampleDB)].Requirement.Requirements R ON QR.RequirementID = R.RequirementID		-- V3.15
		INNER JOIN [$(SampleDB)].Requirement.RequirementRollups QS ON QS.RequirementIDPartOf = QR.RequirementID
		INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements SR ON SR.RequirementID = QS.RequirementIDMadeUpOf
		WHERE QR.RequirementID = @QuestionnaireRequirementID


		-- TRUNCATE THE BASE TABLE TO HOLD THE FINAL DATA
		TRUNCATE TABLE [dbo].[BasePreSelectionCheck]								


		-- NOW GET THE APPROPRIATE EVENT DETAILS FROM THE POOL INTO THE BASE TABLE 
		INSERT INTO [dbo].[BasePreSelectionCheck]
		(
				AuditItemID,
				QuestionnaireRequirementID,
				MatchedODSEventID,
				PartyID,
				MatchedODSEmailAddressID,
				EventCategory,
				EventCategoryID,
				MatchedODSVehicleID
		)
		SELECT DISTINCT
				P.AuditItemID,
				P.QuestionnaireRequirementID,
				P.MatchedODSEventID,
				P.PartyID,
				P.MatchedODSEmailAddressID,
				P.EventCategory,
				P.EventCategoryID,
				P.MatchedODSVehicleID	
		FROM [dbo].[PoolPreSelectionCheck] P
		WHERE QuestionnaireRequirementID = @QuestionnaireRequirementID
			
		------------------------------------------------------------------------------------------------------
		-- IF AFRL Code Validation is set TRUE, then do AFRL validation and Dealer Only Exclusions		
		------------------------------------------------------------------------------------------------------
		IF ISNULL(@ValidateAFRLCodes, 0) = 1  
		BEGIN 
						
			-------------------------------------------------------------------------------------------
			-- NOW CHECK PARTIES WITH BARRED EMAILS - BUT ONLY THOSE WHICH ARE APPLICABLE FOR AFRL !!!	
			-------------------------------------------------------------------------------------------
			IF ISNULL(@UseLatestEmailTable,0) = 1				---Add in lookup of barred emails based on Latest emails received for Party and EventCategory
			BEGIN 
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM dbo.BasePreSelectionCheck SB
				INNER JOIN [$(SampleDB)].Meta.PartyLatestReceivedEmails lre ON lre.PartyID = SB.PartyID
															 AND lre.EventCategoryID = SB.EventCategoryID
				INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = lre.ContactMechanismID
				INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
				INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
				WHERE CMBT.PreventsSelection = 1
				AND CMBT.AFRLFilter = 1
			END
			ELSE BEGIN
				; WITH BarredEmails (PartyID) AS (
					SELECT PCM.PartyID
					FROM [$(SampleDB)].ContactMechanism.vwBlacklistedEmail BCM
					INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
					WHERE BCM.PreventsSelection = 1
					AND BCM.AFRLFilter = 1
				)
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM dbo.BasePreSelectionCheck SB
				INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID
			END				
					
		END

		------------------------------------------------------------------------------------------------------
		-- IF AFRL Code Validation is not set, then do normal Exclusion List					
		------------------------------------------------------------------------------------------------------
		IF ISNULL(@ValidateAFRLCodes, 0) = 0  
		BEGIN 
			
			-----------------------------------------
			-- NOW CHECK PARTIES WITH BARRED EMAILS
			-----------------------------------------
			IF ISNULL(@UseLatestEmailTable,0) = 1	-- Add in lookup of barred emails based on Latest emails received for Party and EventCategory
			BEGIN 
				IF ISNULL(@MCQISurvey,0) = 0		-- Don't exclude for MCQI survey
				BEGIN
					UPDATE SB
					SET SB.DeleteBarredEmail = 1
					FROM dbo.BasePreSelectionCheck SB
					INNER JOIN [$(SampleDB)].Meta.PartyLatestReceivedEmails lre ON lre.PartyID = SB.PartyID
																 AND lre.EventCategoryID = SB.EventCategoryID
					INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms BCM ON BCM.ContactMechanismID = lre.ContactMechanismID
					INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistStrings CMBS ON BCM.BlacklistStringID = CMBS.BlacklistStringID
					INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistTypes CMBT ON CMBS.BlacklistTypeID = CMBT.BlacklistTypeID
					WHERE CMBT.PreventsSelection = 1
				END
			END
			ELSE BEGIN
				; WITH BarredEmails (PartyID) AS (
					SELECT PCM.PartyID
					FROM [$(SampleDB)].ContactMechanism.vwBlacklistedEmail BCM
					INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = BCM.ContactMechanismID
					WHERE BCM.PreventsSelection = 1
				)
				UPDATE SB
				SET SB.DeleteBarredEmail = 1
				FROM dbo.BasePreSelectionCheck SB
				INNER JOIN BarredEmails BE ON BE.PartyID = SB.PartyID
			END			

	END


		-----------------------------------------------------------------
		-- NOW LOG THE EVENTS IN THE SELECTION POOL
		-----------------------------------------------------------------
		IF @UpdateSelectionLogging = 1	--DO THE LOGGING
		  BEGIN

		  	--- Save logging values to a table rather than updating the logging table.  We then write everything at the same time.   
			--- This is so we do not create multiple entries for a single selection in the Logging Audit table. 
			IF OBJECT_ID('tempdb..#LoggingValues') IS NOT NULL
			DROP TABLE #LoggingValues
		
			CREATE TABLE #LoggingValues	
				(
					AuditItemID						BIGINT NOT NULL,
					BarredEmailAddress				BIT NULL

				)

				INSERT INTO #LoggingValues 
				SELECT 	
					SL.AuditItemID,
					SB.DeleteBarredEmail	
				FROM dbo.BasePreSelectionCheck SB
				INNER JOIN dbo.SampleQualityAndSelectionLogging SL ON SL.MatchedODSEventID = SB.MatchedODSEventID
				WHERE SB.MatchedODSVehicleID = SL.MatchedODSVehicleID
				AND SB.MatchedODSEventID = SL.MatchedODSEventID
				AND SB.DeleteBarredEmail = 1
		
		
		
				-- Write all the values to the logging table								--
				UPDATE SL
				SET
					SL.BarredEmailAddress 					= LV.BarredEmailAddress 			   
								FROM #LoggingValues LV
				INNER JOIN dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = LV.AuditItemID

			
		END
		
	COMMIT TRAN

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
