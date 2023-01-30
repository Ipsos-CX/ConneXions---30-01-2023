CREATE PROCEDURE OWAPv2.uspDealerUpdateTransferDealer
	 @OutletFunction NVARCHAR(25)
	,@Manufacturer VARCHAR(50)
	,@Market NVARCHAR(255)
	,@OutletCode NVARCHAR(255)
	,@TransferOutletCode NVARCHAR(255)
	,@IP_SystemUser VARCHAR(50)
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT

AS
SET NOCOUNT ON

/*
	Purpose:	Set up Transfer Dealers 
		
	Version			Date			Developer			Comment
	1.0				14/09/2016		Chris Ross			Original version (adapted from the Sample_ETL Dealer scripts and views)
	1.1				04/10/2016		Chris Ross			13181 - Comment out DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList as we will run seperately, as required. 
	1.2				24/02/2017		Chris Ledger		13621 - Add PreOwned to Function checks
	1.3				27/02/2017		Chris Ledger		13642 - Add in fix to Set Market to DealerEquivalentMarket as drop-downs use Market
	1.4				09/08/2017		Chris Ledger		13922 - Add Bodyshop to Function Checks	IN UAT
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

		CREATE TABLE #DealerTransferChange

			(
				IP_DealerTransferChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction NVARCHAR(25)
				, Manufacturer VARCHAR(50)
				, Market NVARCHAR(255)
				, OutletCode NVARCHAR(255)
				, IP_OutletPartyID INT
				, TransferOutletCode NVARCHAR(255)
				, IP_TransferOutlet NVARCHAR(255)
				, IP_TransferOutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
	

		INSERT INTO #DealerTransferChange

			(
				 Manufacturer
				, OutletFunction			
				, Market
				, OutletCode
				, TransferOutletCode
				, IP_SystemUser
			)
			
			SELECT DISTINCT
				 @Manufacturer
				,@OutletFunction
				,@Market
				,@OutletCode
				,@TransferOutletCode
				,@IP_SystemUser


		---------------------------------------------------------------------------------------------
		-- V1.3 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT DTC.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE DTC SET DTC.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #DealerTransferChange DTC
		INNER JOIN dbo.Markets M ON M.Market = DTC.Market
		---------------------------------------------------------------------------------------------


	-- CHECK MANUFACTURER IS VALID
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer FROM dbo.DW_JLRCSPDealers)
	
	-- CHECK MARKET IS VALID
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market	FROM dbo.DW_JLRCSPDealers)
	
	-- CHECK OUTLET CODE HAS BEEN COMPLETED
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank Outlet Code; '
		WHERE ISNULL(OutletCode, '') = ''
	
	-- CHECK TRANSFERDEALERCODE HAS BEEN COMPLETED
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank TransferDealerCode; '
		WHERE ISNULL(TransferOutletCode, '') = ''	
	
	-- CHECK FUNCTION IS CORRECT
	
		UPDATE #DealerTransferChange
			SET OutletFunction = 'AfterSales'
		WHERE OutletFunction = 'Service'
	
		UPDATE #DealerTransferChange
		SET IP_DataValidated = 0,
			IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Function; '
		WHERE ISNULL(OutletFunction, '') NOT IN ('Sales', 'Aftersales', 'Preowned', 'Bodyshop')			--V1.2 -- V1.4
	
	-- CHECK USER HAS PERMISSION TO AUTHOROSE THESE CHANGES

		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM DealerManagement.vwUsers)
		

	-- WRITE OUTLET PARTY ID TO A LOAD TABLE

	CREATE TABLE #CurrentDealers
	
		(
			OutletFunction NVARCHAR(25)
			, Manufacturer NVARCHAR(255)
			, Market NVARCHAR(255)
			, OutletCode NVARCHAR(255)
			, Outlet NVARCHAR(255)
			, OutletPartyID INT
		)


	INSERT INTO #CurrentDealers

		(
			OutletFunction
			, Manufacturer
			, Market
			, OutletCode
			, Outlet
			, OutletPartyID
		)

			SELECT 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, MAX(Outlet) Outlet
				, OutletPartyID
			FROM dbo.DW_JLRCSPDealers
			GROUP BY 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, Outlet
				, OutletPartyID

		
		UPDATE DTC
			SET IP_DataValidated = CASE WHEN DTC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #DealerTransferChange DTC
		INNER JOIN #CurrentDealers CD ON DTC.OutletFunction = CD.OutletFunction
										AND DTC.Manufacturer = CD.Manufacturer
										AND DTC.Market =  CD.Market
										AND DTC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					DTC1.IP_DealerTransferChangeID
				FROM #DealerTransferChange DTC1
				INNER JOIN #CurrentDealers CD1 ON DTC1.OutletFunction = CD1.OutletFunction
											AND	DTC1.Manufacturer = CD1.Manufacturer
											AND DTC1.Market = CD1.Market
											AND DTC1.OutletCode = CD1.OutletCode
				GROUP BY DTC1.IP_DealerTransferChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON DTC.IP_DealerTransferChangeID = X.IP_DealerTransferChangeID
	

	-- WRITE TRANSFER OUTLET PARTY ID TO LOAD TABLE 
		
		UPDATE DTC
			SET IP_DataValidated = CASE WHEN DTC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_TransferOutletPartyID = CD.OutletPartyID
			, IP_TransferOutlet = CD.Outlet
		FROM #DealerTransferChange DTC
		INNER JOIN #CurrentDealers CD ON DTC.OutletFunction = CD.OutletFunction
										AND DTC.Manufacturer = CD.Manufacturer
										AND DTC.Market =  CD.Market
										AND DTC.TransferOutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					DTC1.IP_DealerTransferChangeID
				FROM #DealerTransferChange DTC1
				INNER JOIN #CurrentDealers CD1 ON DTC1.OutletFunction = CD1.OutletFunction
											AND	DTC1.Manufacturer = CD1.Manufacturer
											AND DTC1.Market = CD1.Market
											AND DTC1.TransferOutletCode = CD1.OutletCode
				GROUP BY DTC1.IP_DealerTransferChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON DTC.IP_DealerTransferChangeID = X.IP_DealerTransferChangeID
	
	
	-- CHECK ONLY ONE DEALER EXISTS FORM THIS MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE DTC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DTC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #DealerTransferChange DTC
		INNER JOIN #CurrentDealers CD ON DTC.OutletFunction = CD.OutletFunction
										AND DTC.Manufacturer = CD.Manufacturer
										AND DTC.Market =  CD.Market
										AND DTC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						DTC1.IP_DealerTransferChangeID
					FROM #DealerTransferChange DTC1
					INNER JOIN #CurrentDealers CD1 ON DTC1.OutletFunction = CD1.OutletFunction
											AND DTC1.Manufacturer = CD1.Manufacturer
											AND DTC1.Market = CD1.Market
											AND DTC1.OutletCode = CD1.OutletCode
					GROUP BY DTC1.IP_DealerTransferChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON DTC.IP_DealerTransferChangeID = X.IP_DealerTransferChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION FOR TRANSFER OUTLET.
	
		UPDATE DTC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DTC.IP_ValidationFailureReasons + 'Transfer Outlet code does not exist in this market; '
		FROM #DealerTransferChange DTC
		LEFT JOIN #CurrentDealers CD ON DTC.OutletFunction = CD.OutletFunction
									AND DTC.Manufacturer = CD.Manufacturer
									AND DTC.Market = CD.Market
									AND DTC.TransferOutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	
	
	

		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #DealerTransferChange 
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


		INSERT INTO Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer
	
			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, IP_OutletPartyID
				, TransferOutletCode
				, IP_TransferOutlet
				, IP_TransferOutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
			)
	
				SELECT DISTINCT
					D.ID
					, DTC.OutletFunction
					, DTC.Manufacturer
					, DTC.Market
					, DTC.OutletCode
					, DTC.IP_OutletPartyID
					, DTC.TransferOutletCode
					, DTC.IP_TransferOutlet
					, DTC.IP_TransferOutletPartyID
					, DTC.IP_SystemUser
					, DTC.IP_DataValidated
					, DTC.IP_ValidationFailureReasons
				FROM #DealerTransferChange DTC
				LEFT JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = DTC.IP_OutletPartyID
														AND D.OutletFunction = DTC.OutletFunction

	
			DROP TABLE #CurrentDealers

			
		----------------------------------------------------------------------
		-- DO THE DEALER NAME UPDATE 
		----------------------------------------------------------------------


		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_TransferDealerChangeID INT
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
					, IP_TransferDealerChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UTD.IP_TransferDealerChangeID) ID
						, UTD.IP_TransferDealerChangeID
						, UTD.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD
					INNER JOIN DealerManagement.vwUsers DU ON DU.UserName = 'OWAPAdmin'
					WHERE UTD.IP_ProcessedDate IS NULL
					AND UTD.IP_DataValidated = 1

		
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
				, U.UserName + ' - Dealer Transfer update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer Transfer update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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


		-- WRITE AUDITITEMIDS BACK TO DEALER TRANSFER TABLE

			UPDATE UTD
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD ON AT.IP_TransferDealerChangeID = UTD.IP_TransferDealerChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET TransferDealer = UTD.IP_TransferOutlet
			, TransferDealerCode = UTD.TransferOutletCode
			, TransferDealerCode_GDD = TD.OutletCode_GDD
			, TransferPartyID = UTD.IP_TransferOutletPartyID
			, SubNationalRegion = TD.SubNationalRegion
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD
		INNER JOIN DBO.DW_JLRCSPDealers D ON UTD.[id] = D.[id]
		INNER JOIN DBO.DW_JLRCSPDealers TD ON UTD.IP_TransferOutletPartyID = TD.OutletPartyID
													AND UTD.OutletFunction = TD.OutletFunction
		WHERE UTD.IP_ProcessedDate IS NULL
		AND UTD.IP_DataValidated = 1



	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UTD
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail AT
		INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer UTD ON AT.AuditItemID = UTD.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		--v1.1 - 
		EXEC Sample_ETL.DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList


		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #DealerTransferChange 

	
		DROP TABLE #DealerTransferChange

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



