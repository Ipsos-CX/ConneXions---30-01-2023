CREATE PROC SelectionOutput.uspCheckBilingualContactDetails
AS

/*
		Purpose:	To ensure bilingual languages entries are present in the OnlineEmailContactDetails table
	
		Version		Date			Developer			Comment
LIVE	1.0			23/10/2017		Chris Ross			Created
LIVE	1.1			27/10/2017		Chris Ledger		Change joins to include Countries and Markets tables to convert from ISOAlpha3 to Market
LIVE	1.2			10/03/2022		Chris Ledger		Task 728 - Fix bug where code errors now another bilingual country added
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

------------------------------------------------------------------------------------------------------------------------
-- Get all countries/markets where Bilingual has been indicated
------------------------------------------------------------------------------------------------------------------------

CREATE TABLE #BilingualCountryIDs
(
	CountryID INT,
	Market VARCHAR(200)
)

INSERT INTO #BilingualCountryIDs (CountryID, Market)
SELECT DISTINCT M.CountryID, 
	M.Market
FROM dbo.DW_JLRCSPDealers D 
	INNER JOIN dbo.Markets M ON M.Market = D.Market
WHERE D.BilingualSelectionOutput = 1
UNION 
SELECT DISTINCT BOP.CountryID, 
	M.Market
FROM SelectionOutput.BilingualOutputPostcodes BOP
	INNER JOIN dbo.Markets M ON M.CountryID = BOP.CountryID
	

IF 'Canada' IN (	SELECT DISTINCT M.Market													-- V1.1
					FROM SelectionOutput.SelectionsToOutput STO
						INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = STO.Market
						INNER JOIN dbo.Markets M ON C.CountryID = M.CountryID)					-- V1.1

		BEGIN	-- V1.2

			------------------------------------------------------------------------------------------------------------------------
			-- As we current only have Canadian Bilingual requirements we will ony check for French Canadian and American English
			-- This will ensure that any future countries with biligual set up will have to be included for this step to continue.
			------------------------------------------------------------------------------------------------------------------------

			-- Check Canadia French Present for bilingual BMQ
			IF 1 <= (	SELECT COUNT(*) 
						FROM SelectionOutput.SelectionsToOutput STO										-- V1.1
							INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = STO.Market			-- V1.1
							INNER JOIN dbo.Markets M ON C.CountryID = M.CountryID						-- V1.1
							INNER JOIN #BilingualCountryIDs BC ON M.Market = BC.Market					-- V1.1
							LEFT JOIN SelectionOutput.OnlineEmailContactDetails OE ON OE.Brand = STO.Brand
																				AND OE.Market = BC.Market
																				AND OE.Questionnaire = STO.Questionnaire
																				AND OE.EmailLanguage = 'Canadian French (Canada)'
						WHERE M.Market = 'Canada'		-- V1.2
							AND OE.ID IS NULL)
				RAISERROR('ERROR: SelectionOutput.uspCheckBilingualContactDetails - Canadian French language missing on Bilingual country lookup.',
										16, -- Severity
											1  -- State 
										) 


			-- Check American English present for bilingual BMQ
			IF 1 <= (	SELECT COUNT(*) 
						FROM SelectionOutput.SelectionsToOutput STO									-- V1.1
							INNER JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = STO.Market		-- V1.1
							INNER JOIN dbo.Markets M ON C.CountryID = M.CountryID					-- V1.1
							INNER JOIN #BilingualCountryIDs BC ON M.Market = BC.Market				-- V1.1
							LEFT JOIN SelectionOutput.OnlineEmailContactDetails OE ON OE.Brand = STO.Brand
																						AND OE.Market = BC.Market
																						AND OE.Questionnaire = STO.Questionnaire
																						AND OE.EmailLanguage = 'American English (USA & Canada)'
						WHERE M.Market = 'Canada'		-- V1.2
							AND OE.ID IS NULL
					)
				RAISERROR('ERROR: SelectionOutput.uspCheckBilingualContactDetails - American English language missing on Bilingual country lookup.',
										16, -- Severity
											1  -- State 
										) 		
	
		END		-- V1.2
						
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH