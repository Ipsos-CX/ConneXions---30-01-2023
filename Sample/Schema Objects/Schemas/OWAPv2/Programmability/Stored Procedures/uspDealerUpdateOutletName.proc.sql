CREATE PROCEDURE OWAPv2.uspDealerUpdateOutletName
	 @OutletFunction			VARCHAR(25)
	,@Manufacturer				NVARCHAR(510)
	,@Market					VARCHAR(255)
	,@OutletCode				NVARCHAR(10)
	,@OutletName				NVARCHAR(510)
	,@OutletName_Short			NVARCHAR(510)
	,@OutletName_NativeLanguage NVARCHAR(510)
	,@IP_SystemUser				VARCHAR(50)
	,@DataValidated				BIT			  OUTPUT
	,@ValidationFailureReasons	VARCHAR(1000) OUTPUT
AS
SET NOCOUNT ON

/*
	Purpose:	Change the dealer's Outlet Name 
		
	Version			Date			Developer			Comment
	1.0				14/09/2016		Chris Ross			Original version (adapted from the Sample_ETL Dealer scripts and views)
	1.1				04/10/2016		Chris Ross			13181 - Comment out DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList as we will run seperately, as required. 
	1.2				28/02/2017		Chris Ledger		13642 - Add in fix to Set Market to DealerEquivalentMarket as drop-downs use Market
	1.3				19/05/2017		Chris Ledger		13897 - ADD in update for LegalOrganisationByLanguage 
	1.4				25/05/2017		Chris Ledger		13897 - Add in DROP #Dealers to avoid bug 
	1.5				29/09/2017		Eddie Thomas		14284 - DDB Bodyshop - OWAP Dealer name updates not working.
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
		CREATE TABLE #OutletNameChange

			(
				IP_OutletNameChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction VARCHAR(25)
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, OutletCode NVARCHAR(10)
				, OutletName NVARCHAR(510)
				, OutletName_Short NVARCHAR(510)
				, OutletName_NativeLanguage NVARCHAR(510)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #OutletNameChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, OutletName
					, OutletName_Short
					, OutletName_NativeLanguage
					, IP_SystemUser
				)

					SELECT DISTINCT
						 @OutletFunction
						,@Manufacturer
						,@Market
						,@OutletCode
						,@OutletName
						,@OutletName_Short
						,@OutletName_NativeLanguage
						,@IP_SystemUser
					


		---------------------------------------------------------------------------------------------
		-- V1.2 Add in fix to set Market to DealerEquivalentMarket as drop-downs use Market
		---------------------------------------------------------------------------------------------
		--SELECT ONC.Market, M.DealerTableEquivMarket, ISNULL(M.DealerTableEquivMarket,M.Market)
		UPDATE ONC SET ONC.Market = ISNULL(M.DealerTableEquivMarket,M.Market)
		FROM #OutletNameChange ONC
		INNER JOIN dbo.Markets M ON M.Market = ONC.Market
		---------------------------------------------------------------------------------------------


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	
	
	-- CHECK OUTLETNAME IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank NewDealerName; '
		WHERE ISNULL(OutletName, '') = ''	

	
	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #OutletNameChange
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
				WHERE GETDATE() < ISNULL(throughdate , '20991231')  -- v1.1
				GROUP BY 
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, OutletPartyID
		
		UPDATE ONC
			SET ONC.IP_DataValidated = CASE WHEN ONC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			ONC.IP_OutletPartyID = CD.OutletPartyID
		FROM #OutletNameChange ONC
		INNER JOIN #CurrentDealers CD ON ONC.OutletFunction = CD.OutletFunction
										AND ONC.Manufacturer = CD.Manufacturer
										AND ONC.Market =  CD.Market
										AND ONC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					ONC1.IP_OutletNameChangeID
				FROM #OutletNameChange ONC1
				INNER JOIN #CurrentDealers CD1 ON ONC1.OutletFunction = CD1.OutletFunction
											AND	ONC1.Manufacturer = CD1.Manufacturer
											AND ONC1.Market = CD1.Market
											AND ONC1.OutletCode = CD1.OutletCode
				GROUP BY ONC1.IP_OutletNameChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON ONC.IP_OutletNameChangeID = X.IP_OutletNameChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE ONC
			SET ONC.IP_DataValidated = 0,
				ONC.IP_ValidationFailureReasons = ONC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #OutletNameChange ONC
		INNER JOIN #CurrentDealers CD ON ONC.OutletFunction = CD.OutletFunction
										AND ONC.Manufacturer = CD.Manufacturer
										AND ONC.Market =  CD.Market
										AND ONC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						ONC1.IP_OutletNameChangeID
					FROM #OutletNameChange ONC1
					INNER JOIN #CurrentDealers CD1 ON ONC1.OutletFunction = CD1.OutletFunction
											AND ONC1.Manufacturer = CD1.Manufacturer
											AND ONC1.Market = CD1.Market
											AND ONC1.OutletCode = CD1.OutletCode
					GROUP BY ONC1.IP_OutletNameChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON ONC.IP_OutletNameChangeID = X.IP_OutletNameChangeID
	
	
	-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE ONC
			SET ONC.IP_DataValidated = 0,
				ONC.IP_ValidationFailureReasons = ONC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #OutletNameChange ONC
		LEFT JOIN #CurrentDealers CD ON ONC.OutletFunction = CD.OutletFunction
									AND ONC.Manufacturer = CD.Manufacturer
									AND ONC.Market = CD.Market
									AND ONC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	



		----------------------------------------------------------------------
		--- CHECK WHETHER INVALID LOAD REASONS and FAIL AND RETURN, IF THERE ARE  
		----------------------------------------------------------------------

		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #OutletNameChange 
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

		INSERT INTO Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, OutletName
				, OutletName_Short
				, OutletName_NativeLanguage
				, OutletCode
				, IP_OutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
				
			)
			
			SELECT DISTINCT
				 D.ID
				, ONC.OutletFunction
				, ONC.Manufacturer
				, onc.Market
				, ONC.OutletName
				, ONC.OutletName_Short
				, ONC.OutletName_NativeLanguage
				, ONC.OutletCode
				, ONC.IP_OutletPartyID
				, ONC.IP_SystemUser
				, ONC.IP_DataValidated
				, ONC.IP_ValidationFailureReasons
			FROM #OutletNameChange ONC
			LEFT JOIN DBO.DW_JLRCSPDealers D ON D.OutletPartyID = ONC.IP_OutletPartyID
													AND D.OutletFunction = ONC.OutletFunction
		
			DROP TABLE #CurrentDealers

		


			
		----------------------------------------------------------------------
		-- DO THE DEALER NAME UPDATE 
		----------------------------------------------------------------------

		-- POPULATE WORKSPACE TABLE TO HOLD AUDIT TRAIL INFO

			CREATE TABLE #AuditTrail
				(
					ID INT
					, IP_OutletNameChangeID INT
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
					, IP_OutletNameChangeID
					, ID_Hierarchy
					, PartyID
					, RoleTypeID
					, PartyRoleID
					, AuditID
					, AuditItemID
				)

					SELECT 
						ROW_NUMBER() OVER (ORDER BY UON.IP_OutletNameChangeID) ID
						, UON.IP_OutletNameChangeID
						, UON.ID
						, DU.PartyID
						, DU.RoleTypeID
						, DU.PartyRoleID
						, NULL AS AuditID
						, NULL AS AuditItemID
					FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
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
				, U.UserName + ' - Dealer name update - ' + CAST(DU.GUID AS NVARCHAR(100)) AS SessionID
				, GETDATE()
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID


		-- WRITE BACK THE CREATED AUDITID USING THE UNIQUE GUID/SESSIONID

			UPDATE AT
				SET AuditID = S.AuditID
			FROM #DistinctUsers DU
			INNER JOIN DealerManagement.vwUsers U ON DU.PartyRoleID = U.PartyRoleID
			INNER JOIN #AuditTrail AT ON DU.PartyRoleID = AT.PartyRoleID
			INNER JOIN [$(AuditDB)].OWAP.Sessions S ON U.UserName + ' - Dealer name update - ' + CAST(DU.GUID AS VARCHAR(100))= S.SessionID


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

			UPDATE UON
				SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON ON AT.IP_OutletNameChangeID = UON.IP_OutletNameChangeID


	--PERFORM UPDATE ON DIMENSION TABLE ROWS
	
		UPDATE D 
			SET Outlet = UON.OutletName
			, TransferDealer = 	
								CASE
									-- ALSO UPDATE TRANSFER OUTLET COLUMNS IF THE OUTLET IS A TRANSFER DEALER
									WHEN D.TransferDealer = D.Outlet AND D.TransferPartyID = D.OutletPartyID 
									THEN UON.OutletName
									ELSE D.TransferDealer 
								END
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
		INNER JOIN dbo.DW_JLRCSPDealers D ON UON.ID = D.ID
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND UON.OutletName <> D.Outlet
	
	-- NOW UPDATE ANY ROWS FOR DEALERS THAT HAVE BEEN TRANSFERRED TO ONE OF THE DEALER HAVING THEIR NAME CHANGED

		UPDATE D 
			SET D.TransferDealer = UON.OutletName 
		FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
		INNER JOIN dbo.DW_JLRCSPDealers D ON UON.IP_OutletPartyID = d.TransferPartyID
													AND UON.OutletCode = D.TransferDealerCode
													AND UON.Manufacturer = D.Manufacturer
													AND UON.Market = D.Market
													AND UON.OutletFunction = D.OutletFunction
													AND GETDATE() < ISNULL(D.ThroughDate , '20991231')  -- v1.3
		WHERE UON.IP_ProcessedDate IS NULL
		AND UON.IP_DataValidated = 1
		AND UON.OutletName <> D.TransferDealer	
	

	-- PERFORM UNPDATE ON SAMPLING RELATIONSHIPS (WHERE SPECIFIED). CREATE TABLE TO HOLD IMPORTER / MANUFACTURER RELATIONSHIPS AND POPULATE IT
	-- WE NEED THIS FOR CORRELATED SUBQUERY BETWEEN DEALERNETWORKS DATA ACCESS VIEW AND NAMECHANGEOVERWRITES TABLE BECAUSE...
	-- YOU CAN'T USE UPDATE..FROM WHERE TARGET IS VIEW WITH 'INSTEAD OF' TRIGGER


	-- CREATE TEMP TABLE OF IMPORTERS

		CREATE TABLE #importers

			(
				ImporterPartyID INT 
				, ManufacturerPartyID INT 
				, ManufacturerOrganisationName NVARCHAR(255) 
				, ImporterOrganisationName NVARCHAR(255)
			)


	-- PUT MANUFACTURERS IMPORTER ORGANISATIONS INTO A TEMP TABLE	

		INSERT INTO #importers

			(
				ImporterPartyID
				, ManufacturerPartyID
				, ManufacturerOrganisationName
				, ImporterOrganisationName
			)

				SELECT
					PR.PartyIDFrom AS ImporterPartyID 
					, PR.PartyIDTo AS ManufacturerPartyID 
					, M.OrganisationName AS ManufacturerOrganisationName 
					, I.OrganisationName AS ImporterOrganisationName
				FROM Party.PartyRelationships AS PR
				INNER JOIN Party.Organisations AS M ON PR.PartyIDTo = M.PartyID
				INNER JOIN Party.Organisations AS I ON PR.PartyIDFrom = I.PartyID
				WHERE PR.PartyIDTo IN (2, 3) -- JAGUAR AND LANDROVER
				AND PR.PartyRelationshipTypeID = 8 -- IMPORTER RELATIONSHIPS	 


	-- PUT NAME CHANGE UPDATES INTO A TABLE SO WE CAN LOOP THROUGH INSERTING INTO UPDATE TRIGGERS ON ORGANISATIONS AND DEALERNETWORK TABLES

		SELECT 
			IDENTITY(INT, 1, 1) AS ID 
			, X.AuditItemID 
			, X.OutletFunction
			, X.Outlet 
			, X.OutletName_Short
			, X.LocalLanguageDealerName 
			, X.OutletPartyID
			, X.OutletCode
		INTO #Dealers
		FROM 
			(
				SELECT 
					MIN(UON.IP_AuditItemID) AS AuditItemID 
					, UON.OutletFunction
					, UON.OutletName AS Outlet
					, UON.OutletName_NativeLanguage AS LocalLanguageDealerName
					, UON.IP_OutletPartyID AS OutletPartyID
					, UON.OutletCode
					, UON.OutletName_Short
				FROM Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON
				INNER JOIN dbo.DW_JLRCSPDealers AS D ON UON.ID = D.ID
				INNER JOIN Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID 
														AND DN.RoleTypeIDFrom = D.OutletFunctionID
				INNER JOIN #importers AS I ON D.ManufacturerPartyID = I.ManufacturerPartyID
											AND DN.PartyIDTo IN (I.ManufacturerPartyID, i.ImporterPartyID)
				WHERE d.OutletPartyID = DN.PartyIDFrom
				AND d.OutletFunctionID = DN.RoleTypeIDFrom
				AND d.ManufacturerPartyID = i.ManufacturerPartyID
				AND UON.IP_ProcessedDate IS NULL
				AND UON.IP_DataValidated = 1
				GROUP BY 
					UON.OutletFunction
					, UON.OutletName
					, UON.OutletName_NativeLanguage
					, UON.IP_OutletPartyID
					, UON.OutletCode
					, UON.OutletName_Short
			) X
	

	-- LOOP THROUGH TABLE INSERTING ROWS INTO LEGALORGANISATION AND DEALERNETWORK DATA ACCESS UPDATE VIEWS


		DECLARE @Counter INT
		SET @Counter = 1
		
		DECLARE @AuditItemID BIGINT
		DECLARE @Outlet NVARCHAR(150)
		DECLARE @LocalLanguageDealerName NVARCHAR(150)
		DECLARE @OutletPartyID INT
		DECLARE @OutletCodeVar NVARCHAR(10)
		DECLARE @OutletFunctionID INT
		DECLARE @OutletNameShort NVARCHAR(150)
		
		WHILE @Counter <= (SELECT MAX(ID) FROM #Dealers)

		BEGIN
			SELECT
				 @AuditItemID = AuditItemID
				, @Outlet = Outlet
				, @LocalLanguageDealerName = LocalLanguageDealerName
				, @OutletPartyID = OutletPartyID
				, @OutletCodeVar = OutletCode
				, @OutletNameShort = OutletName_Short
				, @OutletFunctionID =	CASE OutletFunction 
											WHEN 'Sales' THEN 8 
											WHEN 'Aftersales' THEN 20 
											WHEN 'Bodyshop' THEN 56
											ELSE 0 
										END 
				
			FROM #Dealers
			WHERE ID = @Counter
			
			-- DEALERNETWORKS USES THE LOCAL LANGUAGE DEALER NAME AS THIS SHOULD BE WHAT GOES IN ANY OUTPUT FILES

				UPDATE Party.vwDA_DealerNetworks
					SET	AuditItemID = @AuditItemID 
					, DealerShortName = COALESCE(NULLIF(@LocalLanguageDealerName, ''), 
					@OutletNameShort) 
				WHERE PartyIDFrom = @OutletPartyID
				AND RoleTypeIDFrom = @OutletFunctionID

	
			-- ORGANISATION AND LEGAL ORGANISATION USES THE STANDARD DEALER NAME

				UPDATE Party.vwDA_LegalOrganisations
					SET AuditItemID = @AuditItemID
					, ParentAuditItemID = @AuditItemID
					, OrganisationName = @Outlet
					, LegalName = @LocalLanguageDealerName
					, FromDate = CURRENT_TIMESTAMP
				WHERE PartyID = @OutletPartyID
					

			-- V1.3 LEGAL ORGANISATION BY LANGUAGE USES THE STANDARD DEALER NAME

				UPDATE Party.vwDA_LegalOrganisationsByLanguage
					SET AuditItemID = @AuditItemID
					, ParentAuditItemID = @AuditItemID
					, OrganisationName = @Outlet
					, LegalName = @LocalLanguageDealerName
					, FromDate = CURRENT_TIMESTAMP
				WHERE PartyID = @OutletPartyID
				
										
			SET @Counter = @Counter + 1
		END

	-- STAMP THE RECORDS AS PROCESSES
		
		UPDATE UON
			SET IP_ProcessedDate = GETDATE()
		FROM #Dealers D
		INNER JOIN Sample_ETL.DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName UON ON D.AuditItemID = UON.IP_AuditItemID
		WHERE IP_DataValidated = 1

	
		-- REBUILD FLATTENED DEALER TABLE 
		
		-- V1.4 Add in DROP #Dealers to avoid bug
		DROP TABLE #Dealers
	
		--v1.1 
		EXEC Sample_ETL.DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList

		--- POPULATE RETURN VALUES 
		SELECT @ValidationFailureReasons = IP_ValidationFailureReasons ,
				@DataValidated = IP_DataValidated
		FROM #OutletNameChange 

		DROP TABLE #OutletNameChange


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



