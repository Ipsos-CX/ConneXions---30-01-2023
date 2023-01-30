CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer] ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_TransferDealer]

INSTEAD OF INSERT

AS


	-- Purpose:		Validate data entered via the MS Access dealer database and mark it for processing
	--
	--
	-- Version		Date			Developer			Comment
	-- 1.0			14/05/2012		Martin Riverol		Created
	-- 1.1			13/04/2017		Chris Ledger		Add PreOwned
	-- 1.2			09/08/2017		Chris Ledger		Add Bodyshop - UAT
	-- 1.3			10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	
	-- SET CONNECTION PROPOPERTIES 

		SET NOCOUNT ON
		SET XACT_ABORT ON

	BEGIN TRAN

	-- PERFORM VALIDATION CHECKS

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
				Manufacturer
				, OutletFunction
				, Market
				, OutletCode
				, TransferOutletCode
				, IP_SystemUser
			FROM inserted


	-- CHECK MANUFACTURER IS VALID
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	-- CHECK MARKET IS VALID
	
		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
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
		WHERE ISNULL(OutletFunction, '') NOT IN ('Sales', 'Aftersales', 'PreOwned', 'Bodyshop')		-- V1.2
	
	-- CHECK USER HAS PERMISSION TO AUTHOROSE THESE CHANGES

		UPDATE #DealerTransferChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM [$(SampleDB)].DealerManagement.vwUsers)
		

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
			FROM [$(SampleDB)].dbo.DW_JLRCSPDealers
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
	
	
	-- INSERT DATA INTO LOADING TABLE


	INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_TransferDealer
	
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
			LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = DTC.IP_OutletPartyID
													AND D.OutletFunction = DTC.OutletFunction

		
		DROP TABLE #DealerTransferChange
		DROP TABLE #CurrentDealers
		
	COMMIT TRAN