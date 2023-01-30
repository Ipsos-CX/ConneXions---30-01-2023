CREATE PROC SelectionOutput.uspPopulateHotTopicCodes
AS

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


/*
	Purpose:	Add in any live Hot Topic codes to the SelectionOutput.Online table
	
	Version			Date			Developer			Comment
	1.0				19-11-2018		Chris Ross			BUG 15079 - Original version.
	1.1				26-03-2019		Chris Ross			BUG 15310 - Update to populate the HotTopicCodes column for Pre-Owned PHEV.  Also, include ThroughDate check.
	1.2				01-11-2019		Eddie Thomas		BUG 16667 - Selection output - Add HotTopicCodes field and PHEV flags to CATI output
	1.3				04-03-2020		Chris Ledger		BUG 17941 - Add SOTA HotTopicCode for Service.
	1.4				09-03-2020		Chris Ledger		BUG 17941 - Restrict SOTA Hot Topic to 12 Countries
	1.5				13-03-2020		Chris Ledger		BUG 17941 - Change Russia to Russian Federation
	1.6				04-06-2021		Eddie Thomas		BUG 18235 - PHEV Flags update
*/



	BEGIN TRAN
	
			-------------------------------------------------------------------------------
			-- ADD in PHEV Hot Topic Codes 
			-------------------------------------------------------------------------------
			
			IF (SELECT HotTopicID FROM SelectionOutput.HotTopics 
									WHERE HotTopicCode = 'PHEV' 
									AND ISNULL(ThroughDate, '2099-01-01') > GETDATE()					-- v1.1
				) IS NOT NULL
			BEGIN 
				UPDATE oo
				SET oo.HotTopicCodes = ISNULL(oo.HotTopicCodes, '') + 'PHEV, '
				FROM SelectionOutput.OnlineOutput oo
				INNER JOIN Event.vwEventTypes AS ET ON	ET.EventTypeID = oo.etype AND	
													ET.EventCategory IN ('Sales', 'PreOwned')				-- ON SALES + PREOWNED EVENTS ONLY  -- v1.1
				INNER JOIN Vehicle.ModelVariants	mv ON oo.VariantID = mv.VariantID						-- v1.6
				INNER JOIN Vehicle.PHEVModels		ph ON mv.ModelID =	ph.ModelID							-- v1.6
																		

				WHERE	 oo.ITYPE IN ('H','T') AND
						LEFT(oo.VIN,4) = ph.VINPrefix AND													-- v1.6
						SUBSTRING(oo.VIN, 8, 1) = PH.VINCharacter AND											-- v1.6
						ph.EngineDescription Like '%PHEV%'
				  --AND (oo.Model LIKE '%I-PACE'
				  --     OR (oo.Model in (
						--		'Range Rover',
						--		'Range Rover Sport'
						--		)
						--    AND SUBSTRING(oo.VIN, 8, 1) = 'Y'
					 --     ))
			END  


			-------------------------------------------------------------------------------
			-- ADD IN SOTA HOT TOPIC CODE V1.3
			-------------------------------------------------------------------------------
			
			IF (SELECT HotTopicID FROM SelectionOutput.HotTopics 
				WHERE HotTopicCode = 'SOTA' 
				AND ISNULL(ThroughDate, '2099-01-01') > GETDATE()					
				) IS NOT NULL
			BEGIN 
				UPDATE oo SET oo.HotTopicCodes = ISNULL(oo.HotTopicCodes, '') + 'SOTA, '
				FROM SelectionOutput.OnlineOutput oo
				INNER JOIN Vehicle.HotTopicCodes htc ON oo.VIN = htc.VIN		
				WHERE  oo.ITYPE IN ('H')
				AND htc.HotTopicCode = 'SOTA'
				AND oo.CTRY IN ('Australia','Belgium','Canada','France','Germany','India','Italy','Luxembourg','Russian Federation','South Africa','Spain','United Kingdom','United States of America')	-- V1.4, V1.5
			END 
			

			-------------------------------------------------------------------------------
			-- REMOVE final commas from the Hot Topic list column
			-------------------------------------------------------------------------------
			
			UPDATE oo
			SET oo.HotTopicCodes = SUBSTRING(RTRIM(oo.HotTopicCodes),1,LEN(RTRIM(oo.HotTopicCodes))-1)
			FROM SelectionOutput.OnlineOutput oo
			WHERE RIGHT(RTRIM(oo.HotTopicCodes),1) = ',' 			
			
			
			
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH