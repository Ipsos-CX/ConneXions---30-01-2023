CREATE PROCEDURE OWAPv2.uspDealerUpdatePAGCode
	 @OutletFunction VARCHAR(25)
	,@Manufacturer NVARCHAR(510)
	,@Market NVARCHAR(255)
	,@OutletCode NVARCHAR(10)
	,@PAGCode NVARCHAR(10)
	,@PAGName NVARCHAR(100)
	,@IP_SystemUser VARCHAR(50)
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT


AS
SET NOCOUNT ON

/*
	Purpose:	Change the dealer's PAG Code
		
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

		CREATE TABLE #PAGCodeChange

			(
				IP_PAGCodeChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction VARCHAR(25)
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, PAGCode NVARCHAR(10)
				, PAGName NVARCHAR(100)
				, OutletCode NVARCHAR(10)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #PAGCodeChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, PAGCode
					, PAGName
					, IP_SystemUser
				)

					SELECT DISTINCT
						 @OutletFunction
						,@Manufacturer
						,@Market
						,@OutletCode
						,@PAGCode
						,@PAGName
						,@IP_SystemUser
					

		---------------------------------------------------------------------------------------------
		-- V1.2 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT PCC.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE PCC SET PCC.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #PAGCodeChange PCC
		INNER JOIN dbo.Markets M ON M.Market = PCC.Market
		---------------------------------------------------------------------------------------------



	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #PAGCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #PAGCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #PAGCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #PAGCodeChange
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
			FROM Sample.dbo.DW_JLRCSPDealers
			GROUP BY 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, OutletPartyID

		
		UPDATE SNRC
			SET IP_DataValidated = CASE WHEN SNRC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #PAGCodeChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					SNRC1.IP_PAGCodeChangeID
				FROM #PAGCodeChange SNRC1
				INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND	SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
				GROUP BY SNRC1.IP_PAGCodeChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON SNRC.IP_PAGCodeChangeID = X.IP_PAGCodeChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #PAGCodeChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						SNRC1.IP_PAGCodeChangeID
					FROM #PAGCodeChange SNRC1
					INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
					GROUP BY SNRC1.IP_PAGCodeChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON SNRC.IP_PAGCodeChangeID = X.IP_PAGCodeChangeID
	
	
	---- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #PAGCodeChange SNRC
		LEFT JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
									AND SNRC.Manufacturer = CD.Manufacturer
									AND SNRC.Market = CD.Market
									AND SNRC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	

	

		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #PAGCodeChange 
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


		INSERT INTO Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, PAGCode
				, PAGName
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
				, SNRC.PAGCode
				, SNRC.PAGName
				, SNRC.OutletCode
				, SNRC.IP_OutletPartyID
				, SNRC.IP_SystemUser
				, SNRC.IP_DataValidated
				, SNRC.IP_ValidationFailureReasons
			FROM #PAGCodeChange SNRC
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
					, IP_IP_PAGCodeChangeID INT
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
					, IP_IP_PAGCodeChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UON.IP_PAGCodeChangeID) ID
						, UON.IP_PAGCodeChangeID
						, UON.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode UON
					INNER JOIN DealerManagement.vwUsers DU ON DU.UserName = 'OWAPAdmin'
					WHERE UON.IP_ProcessedDate IS NULL
					AND UON.IP_DataValidated = 1

		
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
				, U.UserName + ' - PAGCode/PAGCode Name update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - PAGCode/PAGCode Name update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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


		-- WRITE AUDITITEMIDS BACK TO DEALER PAG TABLE

			UPDATE UON
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode UON ON AT.IP_IP_PAGCodeChangeID = UON.IP_PAGCodeChangeID

	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET PAGCode = UON.[PAGCode],
				PAGName = UON.[PAGName]
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode UON
		INNER JOIN dbo.DW_JLRCSPDealers D ON UON.ID = D.ID
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND (UON.PAGCode <> D.PAGCode OR UON.PAGName <> D.PAGName)
	
	

	-- PERFORM UPDATE ON SAMPLING RELATIONSHIPS (WHERE SPECIFIED). CREATE TABLE TO HOLD IMPORTER / MANUFACTURER RELATIONSHIPS AND POPULATE IT
	-- WE NEED THIS FOR CORRELATED SUBQUERY BETWEEN DEALERNETWORKS DATA ACCESS VIEW AND NAMECHANGEOVERWRITES TABLE BECAUSE...
	-- YOU CAN'T USE UPDATE..FROM WHERE TARGET IS VIEW WITH 'INSTEAD OF' TRIGGER


	
	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UON
			SET IP_ProcessedDate = GETDATE()
		FROM #AuditTrail D
		INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_PAGCode UON ON D.AuditItemID = UON.IP_AuditItemID
		WHERE IP_DataValidated = 1

	-- REBUILD FLATTENED DEALER TABLE 
	
		--v1.1 - 
		EXEC Sample_ETL.DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList


		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #PAGCodeChange 



		DROP TABLE #PAGCodeChange

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



