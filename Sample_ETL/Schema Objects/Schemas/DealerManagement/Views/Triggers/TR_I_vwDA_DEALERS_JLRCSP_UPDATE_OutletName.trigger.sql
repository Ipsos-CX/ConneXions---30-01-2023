CREATE TRIGGER [DealerManagement].[TR_I_vwDA_DEALERS_JLRCSP_UPDATE_OutletName] ON [DealerManagement].[vwDA_DEALERS_JLRCSP_UPDATE_OutletName]

INSTEAD OF INSERT

AS

	--	Purpose:	Validate data entered via the MS Access dealer database and mark it for processing
	--
	--
	-- Version			Date			Developer			Comment
	-- 1.0				09/05/2012		Martin Riverol		Created
	-- 1.1				16/12/2014		Chris Ross			BUG 11078 - Bug checking for duplicate partyIDs -> should not be including Dealers with current throughDate set.
	-- 1.2				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases

	-- SET LOCAL CONNECTION PROPERTIES

	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRAN

	-- VALIDATE INSERTED RECORDS
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
						OutletFunction
						, Manufacturer
						, Market
						, OutletCode
						, OutletName
						, OutletName_Short
						, OutletName_NativeLanguage
						, IP_SystemUser
					FROM inserted


	-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
		WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
	-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

		UPDATE #OutletNameChange
			SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
		WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
	
	
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
	

	-- INSERT DATA INTO LOADING TABLE

		INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_OutletName

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
			LEFT JOIN [$(SampleDB)].DBO.DW_JLRCSPDealers D ON D.OutletPartyID = ONC.IP_OutletPartyID
													AND D.OutletFunction = ONC.OutletFunction
		
			DROP TABLE #OutletNameChange
			DROP TABLE #CurrentDealers
		
	COMMIT TRAN