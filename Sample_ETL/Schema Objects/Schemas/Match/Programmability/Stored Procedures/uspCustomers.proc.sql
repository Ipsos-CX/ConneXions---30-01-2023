CREATE PROCEDURE [Match].[uspCustomers]
AS

/*
	Purpose:	Match the MatchedODSPersonID and/or MatchedODSOrganisationID in VWT based on trusted ClientCustomerIdentifier
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_Customers
	1.1				16-11-2015		Chris Ross			BUG 12076 - Modified to do matching
	1.2				09-06-2016		Chris Ross			BUG 11771 - Modify to use new vwCustomerRelationships view
	1.3				26-03-2018		Chris Ledger		BUG 14610 - Remove South Africa Only Code
	1.4				21-08-2018		Chris Ledger		BUG 14923 - Change index on #CustomerRelationships to speed up SP	
	1.5				27-11-2018		Chris Ledger		Replace commented out variable to fix Schema Comparison differences.
	1.6				10-01-2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
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

		-- CHECK IF WE'VE GOT ANY RECORDS TO PROCESS
		DECLARE @Count INT
		SELECT @Count = COUNT(*) FROM dbo.VWT WHERE CustomerIdentifierUsable = 1

		IF @Count > 0 
		BEGIN
		
			CREATE TABLE #CustomerRelationships
			(
				MatchedODSPersonID INT, 
				MatchedODSOrganisationID INT, 
				CustomerIdentifierOriginatorPartyID INT, 
				CustomerIdentifier NVARCHAR(60)
			) 
		
			-- POPULATE TABLE WITH DENORMALISED DATA
			INSERT INTO #CustomerRelationships
			(
				MatchedODSPersonID, 
				MatchedODSOrganisationID, 
				CustomerIdentifierOriginatorPartyID, 
				CustomerIdentifier
			)
			SELECT 
				MatchedODSPersonID, 
				MatchedODSOrganisationID, 
				CustomerIdentifierOriginatorPartyID, 
				CustomerIdentifier
			FROM Lookup.vwCustomerRelationships
		

			-- ADD INDEX TO DENORMALISED DATA -- V1.4

			CREATE NONCLUSTERED INDEX idx_CustomerIdentifierOriginatorPartyID 
				ON #CustomerRelationships(CustomerIdentifierOriginatorPartyID, CustomerIdentifier) 
				INCLUDE (MatchedODSPersonID, MatchedODSOrganisationID)
		
			/*
			-- ADD INDEXES TO DENORMALISED DATA

			CREATE NONCLUSTERED INDEX idx_CustomerIdentifierOriginatorPartyID 
				ON #CustomerRelationships(CustomerIdentifierOriginatorPartyID) 
			
			CREATE NONCLUSTERED INDEX idx_CustomerIdentifier 
				ON #CustomerRelationships(CustomerIdentifier) 
			*/		
		
			-- DO THE MATCHING	
			UPDATE V
			SET V.MatchedODSPersonID = ISNULL(CU.MatchedODSPersonID, 0), 
				V.MatchedODSOrganisationID = ISNULL(CU.MatchedODSOrganisationID, 0)
			FROM dbo.VWT V
			INNER JOIN #CustomerRelationships CU ON ISNULL(V.CustomerIdentifier, '') = CU.CustomerIdentifier
												AND V.CustomerIdentifierOriginatorPartyID = CU.CustomerIdentifierOriginatorPartyID
			WHERE V.CustomerIdentifierUsable = 1
		
		
			-------------------------------------------------------------------------------------------
			-- Additional Matching of South African customers for CRM as Customer ID already in use		-- V1.3
			-------------------------------------------------------------------------------------------
			/*	
			-- Create table of South African customer IDs (CRM only) for lookup
			CREATE TABLE #CRM_SouthAfrica_CustomerIDs
				(
					AuditItemID		BIGINT,
					CustIdentifier	NVARCHAR(60)
				)
	
			DECLARE @CountryID INT
			SELECT @CountryID = CountryID FROM [$(SampleDB)].ContactMechanism.Countries WHERE Country = 'South Africa'
			
			INSERT INTO #CRM_SouthAfrica_CustomerIDs (AuditItemID, CustIdentifier)
			SELECT	AuditItemID,
					CASE WHEN LEN(RTRIM(REPLACE(LastName, ' ', ''))) > 1 
							THEN SUBSTRING(MobileTel, 1, 15) + 'P_' + SUBSTRING(REPLACE(LastName, ' ', ''), 1, 43)
						WHEN LEN(RTRIM(REPLACE(OrganisationName, ' ', ''))) > 43 
							THEN SUBSTRING(MobileTel, 1, 15) + 'C_' + SUBSTRING(RTRIM(REPLACE(OrganisationName, ' ', '')),1,43)
						WHEN LEN(RTRIM(REPLACE(OrganisationName, ' ', ''))) > 1 
							THEN SUBSTRING(MobileTel, 1, 15) + 'C_' + SUBSTRING(OrganisationName, 1, 43)
						ELSE NULL
						END
			FROM dbo.vwt v
			WHERE CountryID = @CountryID			-- Only South Africa
			AND CustomerIdentifier LIKE 'CRM_%'		-- only where CRM have already populated the Customer Identifier
			AND ISNULL(MobileTel, '') <> ''		-- and there is a mobile number
			AND (   ISNULL(LastName, '') <> ''	-- and there is either a last name or organisation name
			     OR ISNULL(OrganisationName, '') <> '' )

			-- DO THE MATCHING	
			UPDATE V
			SET V.MatchedODSPersonID = ISNULL(CU.MatchedODSPersonID, 0), 
				V.MatchedODSOrganisationID = ISNULL(CU.MatchedODSOrganisationID, 0)
			FROM dbo.VWT V
			INNER JOIN #CRM_SouthAfrica_CustomerIDs sac ON sac.AuditItemID = V.AuditItemID
													   AND sac.CustIdentifier IS NOT NULL
			INNER JOIN #CustomerRelationships CU ON ISNULL(sac.CustIdentifier , '') = CU.CustomerIdentifier
			WHERE V.MatchedODSPersonID = 0			-- Check not set already via a CRM customer Identifier match.
			  AND V.MatchedODSOrganisationID = 0
			*/
			
			------------------------------
			-- DROP TEMP DATA TABLES
			------------------------------
			DROP TABLE #CustomerRelationships
			-- DROP TABLE #CRM_SouthAfrica_CustomerIDs	-- V1.3
	
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
	
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

