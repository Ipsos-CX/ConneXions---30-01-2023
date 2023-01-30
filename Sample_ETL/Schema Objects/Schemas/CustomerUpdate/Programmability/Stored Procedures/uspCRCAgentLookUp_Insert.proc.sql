CREATE PROCEDURE [CustomerUpdate].[uspCRCAgentLookup_Insert]
/* Purpose:	Insert new records into CRC AgentLookup table
	
	Version			Date			Developer			Comment
	1.0				07/03/2016		Eddie Thomas		Created
	1.1				08/02/2017		Eddie Thomas		BUG FIX : Prevent duplicates from being introduced
	1.2				24/03/2021		Eddie Thomas		BUG 18152 : CRC AGent List format has changed
	1.3				10/05/2021		Eddie Thomas		Truncating lookup before loading new file
	1.4				01/07/2021		Eddie Thomas		Change truncated table even if the there were no records to insert from the staging table
	1.5				05/05/2022		Eddie Thomas		Added AudititemID to the look up, makes it easier to identify the parent file
*/
AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


BEGIN TRAN

		IF EXISTS (SELECT ID FROM Stage.CRCAgents_GlobalList ) 	--V1.4
		BEGIN
		
			TRUNCATE TABLE Lookup.CRCAgents_GlobalList		--V1.3

			-- ADD THE NEW ITEMS TO THE LOOKUP 
			INSERT INTO Lookup.CRCAgents_GlobalList
			(
				[AuditItemID],
				[CDSID],
				[FirstName],
				[Surname],
				[DisplayOnQuestionnaire],
				[DisplayOnWebsite],
				[FullName],
				[Market],
				[MarketCode]
			)
			SELECT DISTINCT
					CUL.AuditItemID,
					CUL.[CDSID],
					CUL.[FirstName],
					CUL.[Surname],
					CUL.[DisplayOnQuestionnaire],
					CUL.[DisplayOnWebsite],
					CUL.[FullName],
					CUL.[Market],
					CUL.[MarketCode]
			FROM Stage.CRCAgents_GlobalList CUL
			LEFT JOIN [Lookup].[CRCAgents_GlobalList] CRC ON	CUL.[CDSID]		= CRC.[CDSID] AND
																CUL.MarketCode	= CRC.MarketCode
													 		
			WHERE	(CRC.ID IS NULL) AND 
					(CUL.AuditItemID = CUL.ParentAuditItemID)
		END
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

