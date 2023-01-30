CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_DealerGroup] ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_DealerGroup]

INSTEAD OF INSERT

AS

	--	Purpose:	Validate data entered via the MS Access dealer database and mark it for processing
	--
	--
	-- Version			Date			Developer			Comment
	-- 1.0				11/05/2012		Martin Riverol		Created
	-- 1.1				21/01/2015		Chris Ross			BUG 11163 - Bug checking for duplicate partyIDs -> should not be including Dealers with current throughDate set.
	-- 1.2				20/02/2017		Chris Ledger		BUG 11163 - Fix difference between LIVE and UAT. LIVE was updated outside of the solution back in 2015. 
	-- 1.3				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	

	-- SET LOCAL CONNECTION PROPERTIES

	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRAN

	-- VALIDATE INSERTED RECORDS
		-- N.B. USER DEFINED DATA TYPES DO NOT APPEAR TO HAVE SCOPE INSIDE TRIGGER THEREFORE DATATYPES EXPLICIT IN TABLE DEFINITION


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
						OutletFunction
						, Manufacturer
						, Market
						, OutletCode
						, DealerGroup
						, NewDealerGroup
						, IP_SystemUser
					FROM inserted


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #DealerGroupChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM [$(SampleDB)].DealerManagement.vwUsers)


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
				FROM [$(SampleDB)].dbo.DW_JLRCSPDealers
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
	

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_DealerGroup

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
			LEFT JOIN [$(SampleDB)].DBO.DW_JLRCSPDealers D ON D.OutletPartyID = DGC.IP_OutletPartyID
													AND D.OutletFunction = DGC.OutletFunction
		
			DROP TABLE #DealerGroupChange
			DROP TABLE #CurrentDealers
			
					
	COMMIT TRAN