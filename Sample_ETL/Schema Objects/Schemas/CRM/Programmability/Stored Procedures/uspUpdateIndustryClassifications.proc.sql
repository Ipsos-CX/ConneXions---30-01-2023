CREATE PROCEDURE [CRM].[uspUpdateIndustryClassifications]

AS

/*
	Purpose:	Update IndustryClassifications for CRM customer data we receive.
	
	Version		Developer			Created			Comment
	1.0			Chris Ross			08/07/2016		Created
	1.1			Chris Ledger		24/03/2021		Task 299 - Add General Enquiry
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

			------------------------------------------------------------------------------------------------------------------------------
			-- REMOVE Leasing Industry Classifications FOR CRM Customers, if no Leasing Industry Classification supplied with CRM customer
			------------------------------------------------------------------------------------------------------------------------------

			-- Get Industry Classification recs to remove ----------------------
			CREATE TABLE #IndClassToRemove
			(
				AuditItemID BIGINT,
				PartyID		BIGINT,
				PartyTypeID INT
			)


			;WITH CTE_CRM_Recs (AuditItemID) AS 
			(
				SELECT V.AuditItemID
				FROM  dbo.VWT V 
					INNER JOIN CRM.Vista_Contract_Sales C ON C.AuditItemID = V.AuditItemID
				UNION 
				SELECT V2.AuditItemID
				FROM dbo.VWT V2
					INNER JOIN CRM.CRCCall_Call C2 ON C2.AuditItemID = V2.AuditItemID
				UNION 
				SELECT V3.AuditItemID
				FROM dbo.VWT V3
					INNER JOIN CRM.DMS_Repair_Service C3 ON C3.AuditItemID = V3.AuditItemID
				UNION 
				SELECT V4.AuditItemID
				FROM dbo.VWT V4
					INNER JOIN CRM.RoadsideIncident_Roadside C4 ON C4.AuditItemID = V4.AuditItemID
				UNION 
				SELECT V5.AuditItemID
				FROM  dbo.VWT V5
					INNER JOIN CRM.General_Enquiry C5 ON C5.AuditItemID = V5.AuditItemID
			)
			INSERT INTO #IndClassToRemove 
			(	
				AuditItemID,
				PartyID,
				PartyTypeID
			)
			SELECT
				V.AuditItemID,
				PC.PartyID,
				PT.PartyTypeID
			FROM dbo.VWT V
				INNER JOIN CTE_CRM_Recs CR ON CR.AuditItemID = V.AuditItemID		-- Only get CRM records
				INNER JOIN [$(SampleDB)].Party.PartyClassifications PC ON PC.PartyID = COALESCE( NULLIF(V.MatchedODSOrganisationID, 0), NULLIF(V.MatchedODSPersonID, 0), NULLIF(V.MatchedODSPartyID, 0) )
				INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON PC.PartyID = IC.PartyID
				INNER JOIN [$(SampleDB)].Party.PartyTypes PT ON PC.PartyTypeID = PT.PartyTypeID
													 AND PT.PartyType = 'Vehicle Leasing Company' --- Only remove Fleet classifications
			WHERE ISNULL (V.SuppliedIndustryClassificationID, 0) = 0
				AND COALESCE( NULLIF(V.MatchedODSOrganisationID, 0), NULLIF(V.MatchedODSPersonID, 0), NULLIF(V.MatchedODSPartyID, 0) ) IS NOT NULL;


			--- Add records to the Audit table prior to the delete
			DECLARE @SysDate DATETIME2
			SET @SysDate = GETDATE()
			
			INSERT INTO [$(AuditDB)].Audit.IndustryClassifications_REMOVED (AuditItemID, PartyID, PartyTypeID, FromDate, RemovedDate)
			SELECT DISTINCT
				T.AuditItemID,
				IC.PartyID,
				IC.PartyTypeID,
				PC.FromDate,
				@SysDate
			FROM #IndClassToRemove T
				INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON T.PartyID = IC.PartyID
																		 AND T.PartyTypeID = IC.PartyTypeID
				INNER JOIN [$(SampleDB)].Party.PartyClassifications PC ON PC.PartyID = IC.PartyID
																	  AND PC.PartyTypeID = IC.PartyTypeID
			
			
			--- Delete the Industry Classification and Party Classification Records
			DELETE IC
			FROM #IndClassToRemove T
				INNER JOIN [$(SampleDB)].Party.IndustryClassifications IC ON T.PartyID = IC.PartyID
																		 AND T.PartyTypeID = IC.PartyTypeID
															  
			DELETE PC
			FROM #IndClassToRemove T
				INNER JOIN [$(SampleDB)].Party.PartyClassifications PC ON T.PartyID = PC.PartyID
																	  AND T.PartyTypeID = PC.PartyTypeID
							


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
