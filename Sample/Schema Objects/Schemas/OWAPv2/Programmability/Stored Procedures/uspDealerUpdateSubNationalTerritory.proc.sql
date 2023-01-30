CREATE PROCEDURE OWAPv2.uspDealerUpdateSubNationalTerritory
	 @OutletFunction VARCHAR(25)
	,@Manufacturer NVARCHAR(510)
	,@Market NVARCHAR(255)
	,@OutletCode NVARCHAR(10)
	,@SubNationalTerritory NVARCHAR(255)
	,@NewSubNationalTerritory NVARCHAR(255)
	,@NewSubNationalRegion NVARCHAR(255)
	,@IP_SystemUser VARCHAR(50)
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT

AS
SET NOCOUNT ON

/*
	Purpose:	Change the dealer's sub national territory and region.  Requires a check to ensure that the pair valid within the dealer heirarchy.
		
	Version			Date			Developer			Comment
	1.0				11/10/2016		Chris Ross			Original version (adapted from the Sample_ETL Dealer scripts and views)
	1.1				28/02/2017		Chris Ledger		13642 - Add in fix to Set Market to DealerEquivalentMarket as drop-downs use Market
	1.2				06/11/2019		Ben King			BUG 16723
	1.3				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
	
*/


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
		---------------------------------------------------------------------------
		-- VALIDATE INSERTED RECORDS
		---------------------------------------------------------------------------
		
		-- N.B. USER DEFINED DATA TYPES DO NOT APPEAR TO HAVE SCOPE INSIDE TRIGGER THEREFORE DATATYPES EXPLICIT IN TABLE DEFINITION

		CREATE TABLE #SubNationalTerritoryChange

			(
				IP_SubNationalTerritoryChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction			VARCHAR(25)
				, Manufacturer				NVARCHAR(510)
				, Market					NVARCHAR(255)
				, SubNationalTerritory		NVARCHAR(255)
				, NewSubNationalTerritory	NVARCHAR(255)
				, NewSubNationalRegion		NVARCHAR(255)
				, OutletCode				NVARCHAR(10)
				, IP_OutletPartyID			INT       
				, IP_SystemUser				VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #SubNationalTerritoryChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, SubNationalTerritory
					, NewSubNationalTerritory
					, NewSubNationalRegion
					, IP_SystemUser
				)

					SELECT DISTINCT
						 @OutletFunction
						,@Manufacturer
						,@Market
						,@OutletCode
						,@SubNationalTerritory
						,@NewSubNationalTerritory
						,@NewSubNationalRegion
						,@IP_SystemUser



		---------------------------------------------------------------------------------------------
		-- V1.1 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT SNTC.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE SNTC SET SNTC.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #SubNationalTerritoryChange SNTC
		INNER JOIN dbo.Markets M ON M.Market = SNTC.Market
		---------------------------------------------------------------------------------------------


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #SubNationalTerritoryChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM DealerManagement.vwUsers)


	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION AND CHECK THERE IS ONLY ONE OUTLETPARTYID

	-- WRITE OUTLET PARTY ID TO A LOAD TABLE

	CREATE TABLE #CurrentDealers
	
		(
			OutletFunction NVARCHAR(25)
			, Manufacturer NVARCHAR(255)
			, Market NVARCHAR(255)
			, OutletCode NVARCHAR(255)
			, OutletPartyID INT
			, ThroughDateSet INT				
		)


	INSERT INTO #CurrentDealers

		(
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, OutletPartyID
			, ThroughDateSet
		)

			SELECT DISTINCT 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, OutletPartyID
				,CASE WHEN GETDATE() < ISNULL(throughdate , '20991231')  
					THEN 0 ELSE 1 END AS ThroughDateSet    
			FROM dbo.DW_JLRCSPDealers




	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN CURRENT DEALER ONE FLAG IT UP
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #SubNationalTerritoryChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
										AND CD.ThroughDateSet = 0			-- v1.1 - Only current "active" dealers
			INNER JOIN 
			
				(
					SELECT 
						SNRC1.IP_SubNationalTerritoryChangeID
					FROM #SubNationalTerritoryChange SNRC1
					INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
											AND CD1.ThroughDateSet = 0
					GROUP BY SNRC1.IP_SubNationalTerritoryChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON SNRC.IP_SubNationalTerritoryChangeID = X.IP_SubNationalTerritoryChangeID


		-- SET OUTLET PARTYID VALUE AND THE RECORD AS VALID IF NOT PREVIOUSLY FLAGGED INVALID 
		UPDATE SNRC
			SET IP_DataValidated = CASE WHEN SNRC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #SubNationalTerritoryChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction		
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
	
	
	-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #SubNationalTerritoryChange SNRC
		LEFT JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
									AND SNRC.Manufacturer = CD.Manufacturer
									AND SNRC.Market = CD.Market
									AND SNRC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	
	
	
	-- CHECK FOR INVALID TERRITORY/REGION COMBINATION WITHIN MARKET  (we have already ascertained that the market is correct for the Dealer in the prev check)
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid SubNationalTerritory/Region combination within current Dealer Hierarchy for Market; '
		FROM #SubNationalTerritoryChange SNRC
		LEFT JOIN (	-- Dealer Hierarchy
						SELECT 	COALESCE(m.DealerTableEquivMarket, m.Market) AS Market,
								snt.SubNationalTerritory,
								snr.SubNationalRegion
						FROM dbo.Markets m 
						INNER JOIN dbo.SubNationalTerritories snt ON snt.MarketID = m.MarketID
						INNER JOIN dbo.SubNationalRegions snr ON snr.SubNationalTerritoryID = snt.SubNationalTerritoryID
					) DH ON DH.Market				= SNRC.Market				
						AND	DH.SubNationalTerritory	= SNRC.NewSubNationalTerritory	
						AND	DH.SubNationalRegion	= SNRC.NewSubNationalRegion
			WHERE DH.SubNationalRegion IS NULL  -- Where supplied params combo not found in dealer heirarchy
	
	
	



		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #SubNationalTerritoryChange 
		WHERE IP_DataValidated <> 1 

		IF @DataValidated = 0
		BEGIN
		 RETURN 0   -- Not validated
		END



		------------------------------------------------------------------------
		------------------------------------------------------------------------
		------------------------------------------------------------------------


	BEGIN TRAN 


		----------------------------------------------------------------------
		-- INSERT DATA INTO DATA DEALER APPOINTMENTS TABLE 
		----------------------------------------------------------------------

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, SubNationalTerritory
				, NewSubNationalTerritory
				, NewSubNationalRegion
				, OutletCode
				, IP_OutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
				
			)
			
			SELECT DISTINCT
				 D.ID
				, SNRC.OutletFunction
				, SNRC.Manufacturer
				, SNRC.Market
				, SNRC.SubNationalTerritory
				, SNRC.NewSubNationalTerritory
				, SNRC.NewSubNationalRegion
				, SNRC.OutletCode
				, SNRC.IP_OutletPartyID
				, SNRC.IP_SystemUser
				, SNRC.IP_DataValidated
				, SNRC.IP_ValidationFailureReasons
			FROM #SubNationalTerritoryChange SNRC
			LEFT JOIN DBO.DW_JLRCSPDealers D ON D.OutletPartyID = SNRC.IP_OutletPartyID
													AND D.OutletFunction = SNRC.OutletFunction
		

			DROP TABLE #CurrentDealers
	
		


			
		----------------------------------------------------------------------
		-- DO THE DEALER NAME UPDATE 
		----------------------------------------------------------------------

		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_SubNationalTerritoryChangeID INT
					, ID_Hierarchy INT
					, PartyID INT
					, RoleTypeID INT
					, PartyRoleID INT
					, AuditID INT
					, AuditItemID INT
				)


			INSERT INTO #AuditTrail
			
				(
					ID
					, IP_SubNationalTerritoryChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY USNR.IP_SubNationalTerritoryChangeID) ID
						, USNR.IP_SubNationalTerritoryChangeID
						, USNR.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
					INNER JOIN DealerManagement.vwUsers DU ON DU.UserName = 'OWAPAdmin'
					WHERE USNR.IP_ProcessedDate IS NULL
					AND USNR.IP_DataValidated = 1

		
		-- GET A DISTINCT LIST OF PARTYROLEIDS FROM WORKSPACE TABLE 

			SELECT DISTINCT
				ROW_NUMBER() OVER (ORDER BY PartyRoleID) ID
				, NEWID() AS GUID
				, PartyRoleID 
			INTO #DistinctUsers
			FROM #AuditTrail AR
			GROUP BY PartyRoleID


		-- CREATE AN AUDITID SESSION FOR EACH PARTY WHO HAS WRITTEN UPDATES

		INSERT INTO [$(AuditDB)].OWAP.vwDA_Sessions

			(
				AuditID
				, UserPartyRoleID
				, SessionID
				, SessionTimeStamp 
			)

			SELECT 
				0 AS AuditID
				, DU.PartyRoleID
				, U.UserName + ' - Dealer SNR update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer SNR update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


		-- NOW CREATE SOME AUDITITEMIDS AS OWAP_ACTIONS

			INSERT INTO [$(AuditDB)].owap.vwDA_Actions
			
				(
					AuditItemID
					, AuditID
					, ActionDate
					, UserPartyID
					, UserRoleTypeID
				)

					SELECT 
						AuditItemID
						, AuditID
						, GETDATE()
						, PartyID
						, RoleTypeID
					FROM #AuditTrail

				
		-- WRITE THE CREATED AUDITITEMIDS BACK TO THE WORKSPACE TABLE

			UPDATE A
			SET AuditItemID = A.ID + B.difference
			FROM #AuditTrail A
			INNER JOIN
				(
					SELECT 
						T.AuditID
						, MIN(A.AuditItemID) - MIN(T.ID) AS difference
					FROM #AuditTrail T 
					INNER JOIN [$(AuditDB)].OWAP.Sessions S ON T.AuditID = S.AuditID
					INNER JOIN [$(AuditDB)].dbo.AuditItems I ON S.AuditID = I.AuditID
					INNER JOIN [$(AuditDB)].OWAP.Actions A ON I.AuditItemID = A.AuditItemID
					GROUP BY T.AuditID
				) B
			ON A.AuditID = B.AuditID


		-- WRITE AUDITITEMIDS BACK TO DEALER APPOINTMENT TABLE

			UPDATE USNR
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR ON AT.IP_SubNationalTerritoryChangeID = USNR.IP_SubNationalTerritoryChangeID


		--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET SubNationalTerritory = USNR.NewSubNationalTerritory,
				SubNationalRegion = USNR.NewSubNationalRegion
		FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
		INNER JOIN dbo.DW_JLRCSPDealers D --ON USNR.ID = D.ID    -- v1.2 Removed specific Dealer ID to link to multi-party Outlet Codes rows (allows for inactive using same code - checks for multi-active parties already done in trigger)
												ON USNR.OutletCode = D.OutletCode
												AND USNR.Manufacturer = D.Manufacturer
												AND USNR.Market = D.Market
												AND USNR.OutletFunction = D.OutletFunction
		WHERE USNR.IP_ProcessedDate IS NULL
		AND USNR.IP_DataValidated = 1
		AND USNR.NewSubNationalTerritory <> D.SubNationalTerritory
		--AND USNR.NewSubNationalRegion <> D.SubNationalRegion --V1.3 REMOVED
	
		-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET SubNationalTerritory = USNR.NewSubNationalTerritory,
				SubNationalRegion = USNR.NewSubNationalRegion
		FROM [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR
		LEFT JOIN dbo.DW_JLRCSPDealers D ON USNR.OutletCode = D.TransferDealerCode
													AND USNR.Manufacturer = D.Manufacturer
													AND USNR.Market = D.Market
													AND USNR.OutletFunction = D.OutletFunction
												--	AND USNR.IP_OutletPartyID = d.TransferPartyID    --- v1.2 Removed so that the we update all associated rows even if mutiples parties on OutletCode (e.g. mutiple inactive parties with same outlet code)
		WHERE USNR.IP_ProcessedDate IS NULL
		AND USNR.IP_DataValidated = 1
		AND USNR.NewSubNationalTerritory <> D.SubNationalTerritory
		--AND USNR.NewSubNationalRegion <> D.SubNationalRegion  --V1.3 REMOVED


	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE USNR
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_UPDATE_SubNationalTerritory USNR ON AT.AuditItemID = USNR.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		--v1.1 - 
		EXEC [$(ETLDB)].DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList



		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #SubNationalTerritoryChange 

		DROP TABLE #SubNationalTerritoryChange

	COMMIT TRAN
	
	RETURN 1

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



