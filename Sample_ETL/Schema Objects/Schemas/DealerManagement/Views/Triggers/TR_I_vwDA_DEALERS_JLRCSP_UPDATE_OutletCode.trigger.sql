CREATE TRIGGER DealerManagement.TR_I_vwDA_DEALERS_JLRCSP_UPDATE_OutletCode ON DealerManagement.vwDA_DEALERS_JLRCSP_UPDATE_OutletCode

INSTEAD OF INSERT

AS

	--	Purpose:	Validate data entered via the MS Access dealer database and mark it for processing
	--							
	--	Version		Date			Developer			Comment
	--	1.0			10/05/2012		Martin Riverol		Created
	--  1.1			21/01/2015		Chris Ross			BUG 11163 - Bug checking for duplicate partyIDs -> should not be including Dealers with current throughDate set.
	--	1.2			20/02/2017		Chris Ledger		BUG 11163 - Fix difference between LIVE and UAT. LIVE was updated outside of the solution back in 2015. 
	-- 	1.3			10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases

	-- SET LOCAL CONNECTION PROPERTIES

		SET NOCOUNT ON
		SET XACT_ABORT ON

		BEGIN TRAN

			-- DO DATA ENTRY VALIDATION

			CREATE TABLE #OutletCodeChange

				(
					 OutletCodeChangeID INT IDENTITY(1,1) NOT NULL
					, OutletFunction VARCHAR(25)
					, Manufacturer VARCHAR(50)
					, Market NVARCHAR(255)
					, OutletCode NVARCHAR(255)
					, NewOutletCode NVARCHAR(255)
					, IP_OutletPartyID INT
					, IP_SystemUser VARCHAR(50)
					, IP_DataValidated BIT DEFAULT(0)
					, IP_ValidationFailureReasons VARCHAR(1000) DEFAULT('')
				)
			
					INSERT INTO #OutletCodeChange

						(
							OutletFunction
							, Manufacturer
							, Market
							, OutletCode
							, NewOutletCode
							, IP_SystemUser
						)
					
							SELECT DISTINCT
								OutletFunction
								, Manufacturer
								, Market
								, OutletCode
								, NewOutletCode
								, IP_SystemUser
							FROM inserted

			
			-- CHECK MANUFACTURER, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

				UPDATE #OutletCodeChange
					SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Manufacturer; '
				WHERE ISNULL(Manufacturer, '') NOT IN (SELECT DISTINCT Manufacturer	FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
			
			
			-- CHECK MARKET, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

				UPDATE #OutletCodeChange
					SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Invalid Market; '
				WHERE ISNULL(Market, '') NOT IN (SELECT DISTINCT Market FROM [$(SampleDB)].dbo.DW_JLRCSPDealers)
			
			
			-- CHECK OUTLETCODE IS POPULATED, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST
			
				UPDATE #OutletCodeChange
					SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank OutletCode; '
				WHERE ISNULL(OutletCode, '') = ''
			
			
			-- CHECK OUTLETNAME IS POPULATED, ADD VALIDATION FAILURE REASON IF IT DOESN'T EXIST

				UPDATE #OutletCodeChange
					SET IP_ValidationFailureReasons = IP_ValidationFailureReasons + 'Blank NewOutletCode; '
				WHERE ISNULL(NewOutletCode, '') = ''	

			
			-- CHECK USERNAME TO ENSURE USER HAS PERMISSION TO MAKE CHANGES

				UPDATE #OutletCodeChange
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

				
				UPDATE OCC
					SET OCC.IP_DataValidated = CASE WHEN OCC.IP_ValidationFailureReasons = '' THEN 1 ELSE 0 END,
					OCC.IP_OutletPartyID = CD.OutletPartyID
				FROM #OutletCodeChange OCC
				INNER JOIN #CurrentDealers CD ON OCC.OutletFunction = CD.OutletFunction
												AND OCC.Manufacturer = CD.Manufacturer
												AND OCC.Market =  CD.Market
												AND OCC.OutletCode = CD.OutletCode
				INNER JOIN 
				
					(
						SELECT 
							OCC1.OutletCodeChangeID
						FROM #OutletCodeChange OCC1
						INNER JOIN #CurrentDealers CD1 ON OCC1.OutletFunction = CD1.OutletFunction
													AND	OCC1.Manufacturer = CD1.Manufacturer
													AND OCC1.Market = CD1.Market
													AND OCC1.OutletCode = CD1.OutletCode
						GROUP BY OCC1.OutletCodeChangeID
						HAVING COUNT(CD1.OutletPartyID) = 1
					) X 
				ON OCC.OutletCodeChangeID = X.OutletCodeChangeID
			
			
			-- CHECK FOR A VALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATION. IF MORE THAN ONE FLAG IT UP

				UPDATE OCC
					SET OCC.IP_DataValidated = 0,
						OCC.IP_ValidationFailureReasons = OCC.IP_ValidationFailureReasons + 'More than one OutletPartyID exists; '
				FROM #OutletCodeChange OCC
				INNER JOIN #CurrentDealers CD ON OCC.OutletFunction = CD.OutletFunction
												AND OCC.Manufacturer = CD.Manufacturer
												AND OCC.Market =  CD.Market
												AND OCC.OutletCode = CD.OutletCode
					INNER JOIN 
					
						(
							SELECT 
								OCC1.OutletCodeChangeID
							FROM #OutletCodeChange OCC1
							INNER JOIN #CurrentDealers CD1 ON OCC1.OutletFunction = CD1.OutletFunction
													AND OCC1.Manufacturer = CD1.Manufacturer
													AND OCC1.Market = CD1.Market
													AND OCC1.OutletCode = CD1.OutletCode
							GROUP BY OCC1.OutletCodeChangeID
							HAVING COUNT(CD1.OutletPartyID) > 1
						) X 
					ON OCC.OutletCodeChangeID = X.OutletCodeChangeID
			
			
			-- CHECK FOR INVALID OUTLETFUNCTION, MANUFACTURER, MARKET AND DEALERCODE COMBINATIONS
			
				UPDATE OCC
					SET OCC.IP_DataValidated = 0,
						OCC.IP_ValidationFailureReasons = OCC.IP_ValidationFailureReasons + 'Invalid OutletFunction, Manufacturer, Market and DealerCode combination; '
				FROM #OutletCodeChange OCC
				LEFT JOIN #CurrentDealers CD ON OCC.OutletFunction = CD.OutletFunction
											AND OCC.Manufacturer = CD.Manufacturer
											AND OCC.Market = CD.Market
											AND OCC.OutletCode = CD.OutletCode
				WHERE CD.OutletPartyID IS NULL	
					
			
			-- INSERT DATA INTO LOADING TABLE

				INSERT INTO DealerManagement.DEALERS_JLRCSP_UPDATE_OutletCode

					(
						 ID
						, OutletFunction
						, Manufacturer
						, Market
						, IP_OutletPartyID
						, OutletCode
						, NewOutletCode
						, IP_SystemUser
						, IP_DataValidated
						, IP_ValidationFailureReasons
					)

						SELECT DISTINCT
							D.ID
							, OCC.OutletFunction
							, OCC.Manufacturer
							, OCC.Market
							, OCC.IP_OutletPartyID
							, OCC.OutletCode
							, OCC.NewOutletCode
							, OCC.IP_SystemUser
							, OCC.IP_DataValidated
							, OCC.IP_ValidationFailureReasons
						FROM #OutletCodeChange OCC
						LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON D.OutletPartyID = OCC.IP_OutletPartyID
																AND D.OutletFunction = OCC.OutletFunction
			
			DROP TABLE #OutletCodeChange
			DROP TABLE #CurrentDealers
			
		COMMIT TRAN