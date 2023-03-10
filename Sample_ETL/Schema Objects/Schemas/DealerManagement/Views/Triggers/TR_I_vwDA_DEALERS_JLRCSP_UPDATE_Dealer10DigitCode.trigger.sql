CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode]
    ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_Dealer10DigitCode]
    INSTEAD OF INSERT
    AS SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRAN

	-- VALIDATE INSERTED RECORDS
		-- N.B. USER DEFINED DATA TYPES DO NOT APPEAR TO HAVE SCOPE INSIDE TRIGGER THEREFORE DATATYPES EXPLICIT IN TABLE DEFINITION

		CREATE TABLE #Dealer10DigitCodeChange

			(
				IP_Dealer10DigitCodeChangeID INT IDENTITY(1,1) NOT NULL
				, OutletFunction VARCHAR(25)
				, Manufacturer NVARCHAR(510)
				, Market NVARCHAR(255)
				, Dealer10DigitCode NVARCHAR(10)
				, OutletCode NVARCHAR(10)
				, IP_OutletPartyID INT
				, IP_SystemUser VARCHAR(50)
				, IP_DataValidated BIT DEFAULT(0)
				, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
			)
		
		
			INSERT INTO #Dealer10DigitCodeChange

				(
					OutletFunction
					, Manufacturer
					, Market
					, OutletCode
					, Dealer10DigitCode
					, IP_SystemUser
				)

					SELECT DISTINCT
						OutletFunction
						, Manufacturer
						, Market
						, OutletCode
						, Dealer10DigitCode
						, IP_SystemUser
					FROM inserted


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #Dealer10DigitCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #Dealer10DigitCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATEION FAILURE REASON IF IT DOESN'T EXIST
	
		UPDATE #Dealer10DigitCodeChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank DealerCode; '
		WHERE ISNULL(OutletCode, '') = ''
	

	-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

		UPDATE #Dealer10DigitCodeChange
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
			GROUP BY 
				OutletFunction
				, Manufacturer
				, Market
				, OutletCode
				, OutletPartyID

		
		UPDATE SNRC
			SET IP_DataValidated = CASE WHEN SNRC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
			IP_OutletPartyID = CD.OutletPartyID
		FROM #Dealer10DigitCodeChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
		INNER JOIN 
		
			(
				SELECT 
					SNRC1.IP_Dealer10DigitCodeChangeID
				FROM #Dealer10DigitCodeChange SNRC1
				INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND	SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
				GROUP BY SNRC1.IP_Dealer10DigitCodeChangeID
				HAVING COUNT(CD1.OutletPartyID) = 1
			) X 
		ON SNRC.IP_Dealer10DigitCodeChangeID = X.IP_Dealer10DigitCodeChangeID
	
	
	-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
		FROM #Dealer10DigitCodeChange SNRC
		INNER JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
										AND SNRC.Manufacturer = CD.Manufacturer
										AND SNRC.Market =  CD.Market
										AND SNRC.OutletCode = CD.OutletCode
			INNER JOIN 
			
				(
					SELECT 
						SNRC1.IP_Dealer10DigitCodeChangeID
					FROM #Dealer10DigitCodeChange SNRC1
					INNER JOIN #CurrentDealers CD1 ON SNRC1.OutletFunction = CD1.OutletFunction
											AND SNRC1.Manufacturer = CD1.Manufacturer
											AND SNRC1.Market = CD1.Market
											AND SNRC1.OutletCode = CD1.OutletCode
					GROUP BY SNRC1.IP_Dealer10DigitCodeChangeID
					HAVING COUNT(CD1.OutletPartyID) > 1
				) X 
			ON SNRC.IP_Dealer10DigitCodeChangeID = X.IP_Dealer10DigitCodeChangeID
	
	
	---- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
	
		UPDATE SNRC
			SET IP_DataValidated = 0,
				IP_ValidationFailureReasons = SNRC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
		FROM #Dealer10DigitCodeChange SNRC
		LEFT JOIN #CurrentDealers CD ON SNRC.OutletFunction = CD.OutletFunction
									AND SNRC.Manufacturer = CD.Manufacturer
									AND SNRC.Market = CD.Market
									AND SNRC.OutletCode = CD.OutletCode
		WHERE CD.OutletPartyID IS NULL
	

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_Dealer10DigitCode

			(
				ID
				, OutletFunction
				, Manufacturer
				, Market
				, Dealer10DigitCode
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
				, SNRC.Dealer10DigitCode
				, SNRC.OutletCode
				, SNRC.IP_OutletPartyID
				, SNRC.IP_SystemUser
				, SNRC.IP_DataValidated
				, SNRC.IP_ValidationFailureReasons
			FROM #Dealer10DigitCodeChange SNRC
			LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = SNRC.IP_OutletPartyID
													AND D.OutletFunction = SNRC.OutletFunction
		
			DROP TABLE #Dealer10DigitCodeChange
			DROP TABLE #CurrentDealers
		
	COMMIT TRAN