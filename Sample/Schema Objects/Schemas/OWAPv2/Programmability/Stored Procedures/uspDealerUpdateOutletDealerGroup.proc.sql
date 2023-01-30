CREATE PROCEDURE OWAPv2.uspDealerUpdateOutletDealerGroup
	 @OutletFunction VARCHAR(25)
	,@Manufacturer NVARCHAR(510)
	,@Market NVARCHAR(255)
	,@OutletCode NVARCHAR(10)
	,@DealerGroup NVARCHAR(510)
	,@NewDealerGroup NVARCHAR(510)
	,@IP_SystemUser VARCHAR(50)
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT

AS
SET NOCOUNT ON

/*
	Purpose:	Change the dealer's group 
		
	Version			Date			Developer			Comment
	1.0				14/09/2016		Chris Ross			Original version (adapted from the Sample_ETL Dealer scripts and views)
	1.1				04/10/2016		Chris Ross			13181 - Comment out DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList as we will run seperately, as required. 
	1.2				28/02/2017		Chris Ledger		13642 - Add in fix to Set Market to DealerEquivalentMarket as drop-downs use Market
	
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
		CREATE TABLE #DealerGroupChange

			(
				IP_DealerGroupChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction VARCHAR(25)
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, OutletCode NVARCHAR(10)
				, DealerGroup NVARCHAR(510)
				, NewDealerGroup NVARCHAR(510)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #DealerGroupChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, DealerGroup
					, NewDealerGroup
					, IP_SystemUser
				)

					SELECT DISTINCT
						 @OutletFunction
						,@Manufacturer
						,@Market
						,@OutletCode
						,@DealerGroup
						,@NewDealerGroup
						,@IP_SystemUser



		---------------------------------------------------------------------------------------------
		-- V1.2 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT DGC.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE DGC SET DGC.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #DealerGroupChange DGC
		INNER JOIN dbo.Markets M ON M.Market = DGC.Market
		---------------------------------------------------------------------------------------------
					

	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #DealerGroupChange
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
			)


		INSERT INTO #CurrentDealers

			(
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, OutletPartyID
			)

				SELECT 
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, OutletPartyID
				FROM dbo.DW_JLRCSPDealers
				WHERE GETDATE() < ISNULL(throughdate , '20991231')  -- v1.1
				GROUP BY 
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, OutletPartyID

		
		UPDATE DGC
			SET IP_DataValidated = CASE WHEN DGC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #DealerGroupChange DGC
		INNER JOIN #CurrentDealers CD ON DGC.OutletFunction = CD.OutletFunction
										AND DGC.Manufacturer = CD.Manufacturer
										AND DGC.Market =  CD.Market
										AND DGC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					DGC1.IP_DealerGroupChangeID
				FROM #DealerGroupChange DGC1
				INNER JOIN #CurrentDealers CD1 ON DGC1.OutletFunction = CD1.OutletFunction
											AND	DGC1.Manufacturer = CD1.Manufacturer
											AND DGC1.Market = CD1.Market
											AND DGC1.OutletCode = CD1.OutletCode
				GROUP BY DGC1.IP_DealerGroupChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON DGC.IP_DealerGroupChangeID = X.IP_DealerGroupChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE DGC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DGC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #DealerGroupChange DGC
		INNER JOIN #CurrentDealers CD ON DGC.OutletFunction = CD.OutletFunction
										AND DGC.Manufacturer = CD.Manufacturer
										AND DGC.Market =  CD.Market
										AND DGC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						DGC1.IP_DealerGroupChangeID
					FROM #DealerGroupChange DGC1
					INNER JOIN #CurrentDealers CD1 ON DGC1.OutletFunction = CD1.OutletFunction
											AND DGC1.Manufacturer = CD1.Manufacturer
											AND DGC1.Market = CD1.Market
											AND DGC1.OutletCode = CD1.OutletCode
					GROUP BY DGC1.IP_DealerGroupChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON DGC.IP_DealerGroupChangeID = X.IP_DealerGroupChangeID
	
	
	-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE DGC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DGC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #DealerGroupChange DGC
		LEFT JOIN #CurrentDealers CD ON DGC.OutletFunction = CD.OutletFunction
									AND DGC.Manufacturer = CD.Manufacturer
									AND DGC.Market = CD.Market
									AND DGC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	




		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #DealerGroupChange 
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
		-- INSERT DATA INTO UPDATE TABLE 
		----------------------------------------------------------------------

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, DealerGroup
				, NewDealerGroup
				, OutletCode
				, IP_OutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
				
			)
			
			SELECT DISTINCT
				 D.ID
				, DGC.OutletFunction
				, DGC.Manufacturer
				, DGC.Market
				, DGC.DealerGroup
				, DGC.NewDealerGroup
				, DGC.OutletCode
				, DGC.IP_OutletPartyID
				, DGC.IP_SystemUser
				, DGC.IP_DataValidated
				, DGC.IP_ValidationFailureReasons
			FROM #DealerGroupChange DGC
			LEFT JOIN DBO.DW_JLRCSPDealers D ON D.OutletPartyID = DGC.IP_OutletPartyID
													AND D.OutletFunction = DGC.OutletFunction
		

			DROP TABLE #CurrentDealers
	
		


			
		----------------------------------------------------------------------
		-- DO THE DEALER NAME UPDATE 
		----------------------------------------------------------------------


		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_DealerGroupChangeID INT
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
					, IP_DealerGroupChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UDG.IP_DealerGroupChangeID) ID
						, UDG.IP_DealerGroupChangeID
						, UDG.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
					INNER JOIN DealerManagement.vwUsers DU ON DU.UserName = 'OWAPAdmin'
					WHERE UDG.IP_ProcessedDate IS NULL
					AND UDG.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer Group update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Group update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


		-- NOW CREATE SOME AUDITITEMIDS AS OWAP_ACTIONS

			INSERT INTO Sample_Audit.owap.vwDA_Actions
			
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

			UPDATE UDG
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG ON AT.IP_DealerGroupChangeID = UDG.IP_DealerGroupChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET CombinedDealer = UDG.NewDealerGroup
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
		INNER JOIN dbo.DW_JLRCSPDealers D ON UDG.ID = D.ID
		WHERE UDG.IP_ProcessedDate IS NULL
		AND UDG.IP_DataValidated = 1
		AND UDG.NewDealerGroup <> D.CombinedDealer
	
	-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET CombinedDealer = UDG.NewDealerGroup
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG
		INNER JOIN dbo.DW_JLRCSPDealers D ON UDG.IP_OutletPartyID = d.TransferPartyID
													AND UDG.OutletCode = D.TransferDealerCode
													AND UDG.Manufacturer = D.Manufacturer
													AND UDG.Market = D.Market
													AND UDG.OutletFunction = D.OutletFunction
		WHERE UDG.IP_ProcessedDate IS NULL
		AND UDG.IP_DataValidated = 1
		AND UDG.NewDealerGroup <> D.CombinedDealer
	

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UDG
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup UDG ON AT.AuditItemID = UDG.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		--v1.1 
		 EXEC Sample_ETL.DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList


		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #DealerGroupChange 

	
		DROP TABLE #DealerGroupChange

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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage

	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

