CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_Town] ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Town]

INSTEAD OF INSERT

AS

	--	Purpose:	Validate data entered via the MS Access dealer database and mark it for processing
	--
	--
	-- Version			Date			Developer			Comment
	-- 1.0				14/05/2012		Martin Riverol		Created
	

	-- SET LOCAL CONNECTION PROPERTIES

	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRAN

	-- VALIDATE INSERTED RECORDS
		-- N.B. USER DEFINED DATA TYPES DO NOT APPEAR TO HAVE SCOPE INSIDE TRIGGER THEREFORE DATATYPES EXPLICIT IN TABLE DEFINITION

		CREATE TABLE #DealerTownChange

			(
				IP_DealerTownChangeID INT IDENTITY(1,1) NOT NULL
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, Town NVARCHAR(255)
				, NewTown NVARCHAR(255)
				, OutletCode NVARCHAR(10)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #DealerTownChange

				(
					Manufacturer
					, Market
					, OutletCode
					, Town
					, NewTown
					, IP_SystemUser
				)

					SELECT DISTINCT
						Manufacturer
						, Market
						, OutletCode
						, Town
						, NewTown
						, IP_SystemUser
					FROM inserted


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerTownChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #DealerTownChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #DealerTownChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #DealerTownChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid User Credentials for Login: ' + IP_SystemUser + '; '
		WHERE ISNULL(IP_SystemUser, '') NOT IN (SELECT UserName FROM [$(SampleDB)].DealerManagement.vwUsers)


	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION AND CHECK THERE IS ONLY ONE OUTLETPARTYID
	
			-- WRITE OUTLET PARTY ID TO A LOAD TABLE

		CREATE TABLE #CurrentDealers
		
			(
				Manufacturer NVARCHAR(255)
				, Market NVARCHAR(255)
				, OutletCode NVARCHAR(255)
				, OutletPartyID INT
			)


		INSERT INTO #CurrentDealers

			(
				Manufacturer
				, Market
				, OutletCode
				, OutletPartyID
			)

				SELECT 
					Manufacturer
					, Market
					, OutletCode
					, OutletPartyID
				FROM [$(SampleDB)].dbo.DW_JLRCSPDealers
				GROUP BY 
					Manufacturer
					, Market
					, OutletCode
					, OutletPartyID

		
		UPDATE DTC
			SET IP_DataValidated = CASE WHEN DTC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #DealerTownChange DTC
		INNER JOIN #CurrentDealers CD ON DTC.Manufacturer = CD.Manufacturer
										AND DTC.Market =  CD.Market
										AND DTC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					DTC1.IP_DealerTownChangeID
				FROM #DealerTownChange DTC1
				INNER JOIN #CurrentDealers CD1 ON DTC1.Manufacturer = CD1.Manufacturer
											AND DTC1.Market = CD1.Market
											AND DTC1.OutletCode = CD1.OutletCode
				GROUP BY DTC1.IP_DealerTownChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON DTC.IP_DealerTownChangeID = X.IP_DealerTownChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE DTC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DTC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #DealerTownChange DTC
		INNER JOIN #CurrentDealers CD ON DTC.Manufacturer = CD.Manufacturer
										AND DTC.Market =  CD.Market
										AND DTC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						DTC1.IP_DealerTownChangeID
					FROM #DealerTownChange DTC1
					INNER JOIN #CurrentDealers CD1 ON DTC1.Manufacturer = CD1.Manufacturer
											AND DTC1.Market = CD1.Market
											AND DTC1.OutletCode = CD1.OutletCode
					GROUP BY DTC1.IP_DealerTownChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON DTC.IP_DealerTownChangeID = X.IP_DealerTownChangeID
	
	
	-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE DTC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = DTC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #DealerTownChange DTC
		LEFT JOIN #CurrentDealers CD ON DTC.Manufacturer = CD.Manufacturer
									AND DTC.Market = CD.Market
									AND DTC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_Town

			(
				Manufacturer
				, Market
				, Town
				, NewTown
				, OutletCode
				, IP_OutletPartyID
				, IP_SystemUser
				, IP_DataValidated
				, IP_ValidationFailureReasons
				
			)
			
			SELECT DISTINCT
				DTC.Manufacturer
				, DTC.Market
				, DTC.Town
				, DTC.NewTown
				, DTC.OutletCode
				, DTC.IP_OutletPartyID
				, DTC.IP_SystemUser
				, DTC.IP_DataValidated
				, DTC.IP_ValidationFailureReasons
			FROM #DealerTownChange DTC



		
			DROP TABLE #DealerTownChange
			DROP TABLE #CurrentDealers
		
	COMMIT TRAN