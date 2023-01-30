CREATE PROCEDURE [DealerManagement].[uspUpdateFranchises]

AS

SET NOCOUNT ON

/*

Release		Version		Created			Author			Description	
-------		-------		------			-------			
LIVE		1.0			2021-01-21		Chris Ledger	Created from Various Sample_ETL.DealerManagement SPs
LIVE		1.1			2021-01-28		Chris Ledger	Add Auditing of Franchises_Load table 
LIVE		1.2			2021-01-29		Chris Ledger	Extend auditing
LIVE		1.3			2021-02-04		Chris Ledger	Change coding of SubNationalRegion for Bodyshop
LIVE		1.4			2021-03-31		Chris Ledger	Add conversion of NULL to blank for FranchiseCICode to fix bug with 3 franchises without FranchiseCICodes
LIVE		1.5			2021-05-10		Chris Ledger	Change coding of SubNationalRegion to Market Number for US
LIVE		1.6			2021-05-10		Chris Ledger	Change coding of SubNationalTerritory to Market + ' Territory' for non US markets
LIVE		1.7         2021-05-25      Ben King        TASK 464 - Historic data  Hierarchy file - terminated retailers	
LIVE		1.8			2021-06-23		Chris Ledger	TASK 517 - China Region update
LIVE		1.9			2021-07-16		Chris Ledger	TASK 556 - Only set ThroughDate for Terminated dealers
LIVE		1.10        2021-08-12      Ben King        TASK 577 - PAGName to be filled in using FIMs Retailer Locality field
LIVE		1.11        2021-08-17      Ben King        TASK 578 - China 3 digit code
LIVE		1.12		2021-11-10		Chris Ledger	TASK 692 - Change coding of SubNationalRegion for Sales,PreOwned & AfterSales to use SubNationalRegion if available 
LIVE		1.13        2021-12-13      Ben King        TASK 722 - Region and Sub National Territory naming 
LIVE		1.14		2022-01-06		Chris Ledger	TASK 579 - Add LanguageID
LIVE		1.15		2022-01-17		Chris Ledger	TASK 751 - Add ApprovedUser
LIVE		1.16		2022-03-03		Chris Ledger	TASK 722 - Set Belgium & Luxembourg SubNational/SubNationalTerritory to BELUX
LIVE        1.17        2022-03-28      Ben King        TASK 838 - 19473 - Hierarchy - Dealer Group naming

*/
	
	-- DECLARE LOCAL VARIABLES 
	DECLARE @ErrorCode INT
	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)


	BEGIN TRY

		BEGIN TRANSACTION

			------------------------------------------------------------------------------------------------------------------------------		
			/* CREATE A NEW AUDIT TRAIL FOR THE DATA OF FILETYPE 21 - FRANCHISE UPDATES */
			------------------------------------------------------------------------------------------------------------------------------		
			DECLARE @AuditID INT
			DECLARE @RecsToUpdate INT
			DECLARE @FileName VARCHAR(100)

			CREATE TABLE #AuditTrail
			(	ID								INT,
				IP_ID							INT,
				AuditID							INT,
				AuditItemID						INT,
				ImportAuditItemID				INT,		-- V1.1
				LoadType						CHAR(1),	-- V1.2
				Update_FranchiseTradingTitle	CHAR(1),	-- V1.2
				Update_FranchiseCICode			CHAR(1),	-- V1.2
				Update_Address					CHAR(1),	-- V1.2
				Update_LocalLanguage			CHAR(1)		-- V1.2
			)

			INSERT INTO #AuditTrail
			(
				ID,
				IP_ID,
				AuditID,
				AuditItemID,
				ImportAuditItemID,							-- V1.1
				LoadType,									-- V1.2
				Update_FranchiseTradingTitle,				-- V1.2
				Update_FranchiseCICode,						-- V1.2
				Update_Address,								-- V1.2
				Update_LocalLanguage						-- V1.2
			)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY F.IP_ID) ID,
				F.IP_ID,
				NULL AS AuditID,
				NULL AS AuditItemID,
				F.ImportAuditItemID,						-- V1.1
				'U' AS LoadType,							-- V1.2
				F.Update_FranchiseTradingTitle,				-- V1.2
				F.Update_FranchiseCICode,					-- V1.2
				F.Update_Address,							-- V1.2
				F.Update_LocalLanguage						-- V1.2
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
			ORDER BY F.Update_FranchiseTradingTitle DESC, 
				F.Update_FranchiseCICode DESC
		

			SELECT @RecsToUpdate = COUNT(*), 
				@FileName = F.ImportFileName 
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
			GROUP BY F.ImportFileName
		
			SELECT @AuditID = MAX(AuditID) + 1 FROM [$(AuditDB)].dbo.Audit;
				
			INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
			SELECT @AuditID
				
			INSERT INTO [$(AuditDB)].dbo.Files 
			(
				AuditID,
				ActionDate,
				FileName,
				FileRowCount,
				FileTypeID
			)
			SELECT 
				@AuditID AS AuditID,
				GETDATE() AS ActionDate,
				'Update Franchises: ' + @FileName AS FileName,
				@RecsToUpdate AS FileRowCount,
				21 AS FileTypeID
			FROM #AuditTrail A
			GROUP BY A.AuditID			
			
			UPDATE A 
			SET AuditID = @AuditID, 
				AuditItemID = A.ID + (SELECT MAX(AuditItemID) + 1 FROM [$(AuditDB)].dbo.AuditItems)
			FROM #AuditTrail A
			
			INSERT INTO [$(AuditDB)].dbo.AuditItems
			(
				AuditID,
				AuditItemID
			)
			SELECT 
				AuditID,
				AuditItemID
			FROM #AuditTrail

			INSERT INTO [$(AuditDB)].Audit.Franchises_Load		-- V1.1
			(	AuditItemID,
				ImportAuditItemID,
				LoadType,										-- V1.2
				Update_FranchiseTradingTitle,					-- V1.2
				Update_FranchiseCICode,							-- V1.2
				Update_Address,									-- V1.2
				Update_LocalLanguage							-- V1.2
			)
			SELECT
				AuditItemID,
				ImportAuditItemID,
				LoadType,										-- V1.2
				Update_FranchiseTradingTitle,					-- V1.2
				Update_FranchiseCICode,							-- V1.2
				Update_Address,									-- V1.2
				Update_LocalLanguage							-- V1.2
			FROM #AuditTrail			
			------------------------------------------------------------------------------------------------------------------------------		
				
				
			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE AUDITITEMIDS BACK TO FRANCHISE_LOAD TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE F
			SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
				INNER JOIN DealerManagement.Franchises_Load F ON AT.IP_ID = F.IP_ID
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- LOOP THROUGH DEALER NETWORKS TABLE INSERTING ROWS INTO LEGALORGANISATION AND DEALERNETWORK DATA ACCESS UPDATE VIEWS FOR DEALER NAME AND CODE CHANGES
			------------------------------------------------------------------------------------------------------------------------------		

			CREATE TABLE #DealerNetworkUpdates
			(	ID INT,
				IP_ID INT,
				AuditItemID INT,
				Outlet NVARCHAR(150),
				OutletCode NVARCHAR(20),
				OutletPartyID INT,
				OutletFunctionID INT
			)

			INSERT INTO #DealerNetworkUpdates
			(
				ID,
				IP_ID,
				AuditItemID,
				Outlet,
				OutletCode,
				OutletPartyID,
				OutletFunctionID
			)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY F.IP_ID) AS ID,
				F.IP_ID,
				F.IP_AuditItemID AS AuditItemID,
				F.FranchiseTradingTitle AS Outlet,
				F.FranchiseCICode AS OutletCode,
				F.IP_OutletPartyID AS OutletPartyID,
				FTOF.OutletFunctionID AS OutletFunctionID
			FROM #AuditTrail A
				INNER JOIN DealerManagement.vwFranchises_Update F ON A.IP_ID = F.IP_ID
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND (F.Update_FranchiseTradingTitle = 'Y' OR F.Update_FranchiseCICode = 'Y')

			DECLARE @Counter INT
			SET @Counter = 1
		
			DECLARE @AuditItemID BIGINT
			DECLARE @Outlet NVARCHAR(150)
			DECLARE @OutletCode NVARCHAR(20)
			DECLARE @OutletPartyID INT
			DECLARE @OutletFunctionID INT
			DECLARE @NewOutlet NVARCHAR(150) = N''
			DECLARE @NewOutletPartyID INT = 0
			DECLARE @NumberOutletNameCodeUpdates INT
		
			SELECT @NumberOutletNameCodeUpdates = COUNT(*) 
			FROM #DealerNetworkUpdates

			WHILE @Counter <= (@NumberOutletNameCodeUpdates)

				BEGIN
					SELECT 
						@AuditItemID = U.AuditItemID,
						@Outlet = U.Outlet,
						@OutletCode = U.OutletCode,
						@OutletPartyID = U.OutletPartyID,
						@OutletFunctionID = U.OutletFunctionID
					FROM #DealerNetworkUpdates U
					WHERE U.ID = @Counter
			
					-- DEALERNETWORKS USES THE LOCAL LANGUAGE DEALER NAME AS THIS SHOULD BE WHAT GOES IN ANY OUTPUT FILES
					UPDATE Party.vwDA_DealerNetworks
					SET	AuditItemID = @AuditItemID, 
						DealerShortName = @Outlet,
						DealerCode = @OutletCode
					WHERE PartyIDFrom = @OutletPartyID
						AND RoleTypeIDFrom = @OutletFunctionID

					IF @NewOutletPartyID <> @OutletPartyID
						BEGIN
							SET @NewOutletPartyID = @OutletPartyID
							SET @NewOutlet = ''
						END

					IF @NewOutlet <> @Outlet
						BEGIN
							-- ORGANISATION AND LEGAL ORGANISATION USES THE STANDARD DEALER NAME
							UPDATE Party.vwDA_LegalOrganisations
							SET AuditItemID = @AuditItemID,
								ParentAuditItemID = @AuditItemID,
								OrganisationName = @Outlet,
								LegalName = @Outlet,
								FromDate = CURRENT_TIMESTAMP
							WHERE PartyID = @OutletPartyID

							SET @NewOutlet = @Outlet
						END
					
						
					SET @Counter = @Counter + 1
				END
			------------------------------------------------------------------------------------------------------------------------------		

			
			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE DEALERNAME
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D 
			SET D.Outlet = F.FranchiseTradingTitle
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.DW_JLRCSPDealers D ON F.IP_OutletPartyID = D.OutletPartyID
														AND FTOF.OutletFunctionID = D.OutletFunctionID
														AND F.IP_ManufacturerPartyID = D.ManufacturerPartyID
			WHERE F.FranchiseTradingTitle <> D.Outlet
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE TRANSFER DEALERNAME
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D 
			SET D.TransferDealer = F.FranchiseTradingTitle
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.DW_JLRCSPDealers D ON F.IP_OutletPartyID = D.OutletPartyID
														AND FTOF.OutletFunctionID = D.OutletFunctionID
														AND F.IP_ManufacturerPartyID = D.ManufacturerPartyID
			WHERE F.FranchiseTradingTitle <> D.TransferDealer
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE OUTLET CODES
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D 
			SET D.OutletCode = F.FranchiseCICode
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.DW_JLRCSPDealers D ON F.IP_OutletPartyID = D.OutletPartyID
														AND FTOF.OutletFunctionID = D.OutletFunctionID
														AND F.IP_ManufacturerPartyID = D.ManufacturerPartyID
			WHERE F.FranchiseCICode <> D.OutletCode
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE TRANSFER DEALER CODES
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D 
			SET D.TransferDealerCode = F.FranchiseCICode
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.DW_JLRCSPDealers D ON F.IP_OutletPartyID = D.OutletPartyID
														AND FTOF.OutletFunctionID = D.OutletFunctionID
														AND F.IP_ManufacturerPartyID = D.ManufacturerPartyID
			WHERE F.FranchiseCICode <> D.TransferDealerCode
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- ASSIGN PARENT POSTAL ADDRESS AUDITITEMID IN DEALER APPOINTMENT TABLE
			------------------------------------------------------------------------------------------------------------------------------					
			UPDATE FL
			SET FL.IP_AddressParentAuditItemID = P.AddressParentAuditItemID
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN DealerManagement.Franchises_Load FL ON F.IP_ID = FL.IP_ID
				INNER JOIN (	SELECT
									'' AS BuildingName,
									'' AS SubStreetNumber, 
									'' AS SubStreet, 
									'' AS StreetNumber, 
									COALESCE(F.Address1, '') AS Street, 
									COALESCE(F.Address2, '') AS SubLocality, 
									COALESCE(F.Address3, '') AS Locality, 
									COALESCE(F.AddressTown, '') AS Town, 
									COALESCE(F.AddressCountyDistrict, '') AS Region, 
									COALESCE(F.AddressPostcode, '') AS PostCode, 
									F.IP_CountryID AS CountryID, 
									MIN(F.IP_AuditItemID) AS AddressParentAuditItemID
								FROM DealerManagement.vwFranchises_Update F
								WHERE F.IP_ProcessedDate IS NULL
									AND F.IP_DataValidated = 1
									AND F.Update_Address = 'Y'
								GROUP BY
									COALESCE(F.Address1, ''), 
									COALESCE(F.Address2, ''), 
									COALESCE(F.Address3, ''), 
									COALESCE(F.AddressTown, ''), 
									COALESCE(F.AddressCountyDistrict, ''), 
									COALESCE(F.AddressPostcode, ''), 
									F.IP_CountryID) AS P ON P.Street = COALESCE(F.Address1, '')
															AND P.SubLocality = COALESCE(F.Address2, '')
															AND P.Locality = COALESCE(F.Address3, '')
															AND P.Town = COALESCE(F.AddressTown, '')
															AND P.Region = COALESCE(F.AddressCountyDistrict, '')
															AND P.PostCode = COALESCE(F.AddressPostCode, '')
															AND P.CountryID = F.IP_CountryID
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND F.Update_Address = 'Y'
			------------------------------------------------------------------------------------------------------------------------------		

		
			------------------------------------------------------------------------------------------------------------------------------		
			-- NOW ADD ADDRESSES
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO ContactMechanism.vwDA_PostalAddresses
			(
				AuditItemID,
				AddressParentAuditItemID,
				ContactMechanismID,
				ContactMechanismTypeID,
				BuildingName,
				SubStreetNumber,
				SubStreet,
				StreetNumber,
				Street,
				SubLocality,
				Locality,
				Town,
				Region,
				PostCode,
				CountryID,
				AddressChecksum
			)
			SELECT DISTINCT
				F.IP_AuditItemID,
				F.IP_AddressParentAuditItemID,
				0 AS ContactMechanismID, 
				1 AS ContactMechanismTypeID,	-- Postal address
				'' AS BuildingName,
				'' AS SubStreetNumber, 
				'' AS SubStreet, 
				'' AS StreetNumber, 
				COALESCE(F.Address1, '') AS Street, 
				COALESCE(F.Address2, '') AS SubLocality, 
				COALESCE(F.Address3, '') AS Locality, 
				COALESCE(F.AddressTown, '') AS Town, 
				COALESCE(F.AddressCountyDistrict, '') AS Region, 
				COALESCE(F.AddressPostcode, '') AS PostCode, 
				F.IP_CountryID AS CountryID,
				0 AS AddressChecksum
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND F.Update_Address = 'Y'
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- REMOVE EXISTING PARTY CONTACT MECHANISM
			DELETE FROM PCM
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON F.IP_OutletPartyID = PCM.PartyID
																		AND F.IP_ContactMechanismID = PCM.ContactMechanismID
			WHERE F.Update_Address = 'Y'
			------------------------------------------------------------------------------------------------------------------------------		

		
			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE CONTACTMECHANISM BACK TO DEALER APPOINTMENT TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE FL
			SET FL.IP_ContactMechanismID = APA.ContactMechanismID
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN DealerManagement.Franchises_Load FL ON F.IP_ID = FL.IP_ID
				INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON F.IP_AuditItemID = APA.AuditItemID
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND ISNULL(F.IP_CountryID, 0) > 0
				AND F.Update_Address = 'Y'
			------------------------------------------------------------------------------------------------------------------------------		
			

			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE PARTYPOSTALADDDRESSES (I.E. TIE NEW DEALERS TO THEIR ADDRESSES)
			------------------------------------------------------------------------------------------------------------------------------		
			--;WITH CTE_MinDate (IP_ContactMechanism, IP_OutletPartyID, FromDate) AS
			--(			
			--	SELECT 
			--		F.ContactMechanismID, 
			--		F.OutletPartyID, 
			--		MIN(COALESCE(F.FranchiseStartDate,GETDATE())) AS FromDate
			--	FROM DealerManagement.vwFranchises_New FN
			--	WHERE F.IP_ProcessedDate IS NULL
			--		AND F.IP_DataValidated = 1
			--		AND F.OutletPartyID IS NOT NULL
			--		AND F.Update_Address = 'Y'
			--		AND F.IP_AddressParentAuditItemID IS NOT NULL	-- V1.7 ONLY ADD IF NEW CONTACT MECHANISM
			--	GROUP BY F.ContactMechanismID, F.IP_OutletPartyID
			--)
			INSERT INTO ContactMechanism.vwDA_PartyPostalAddresses
			(
				AuditItemID, 
				ContactMechanismID, 
				PartyID, 
				FromDate, 
				ContactMechanismPurposeTypeID
			)
			SELECT
				F.IP_AuditItemID,
				F.IP_ContactMechanismID, 
				F.IP_OutletPartyID, 
				GETDATE() AS FromDate,
				2 AS ContactMechanismPurposeTypeID --Main business address
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND ISNULL(F.IP_CountryID, 0) > 0
				AND F.Update_Address = 'Y'
			GROUP BY F.IP_AuditItemID,
				F.IP_ContactMechanismID, 
				F.IP_OutletPartyID
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- ADD NEW ADDRESSES
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO ContactMechanism.vwDA_PartyPostalAddresses
			(
				AuditItemID, 
				ContactMechanismID, 
				PartyID, 
				FromDate, 
				ContactMechanismPurposeTypeID
			)
			SELECT 	MIN(F.IP_AuditItemID) AS AuditItemID,
				MAX(F.IP_ContactMechanismID) AS ContactMechanismID,
				F.IP_OutletPartyID,
				GETDATE() AS FromDate,
				2 AS ContactMechanismPurposeTypeID	-- Main business address
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.Update_Address = 'Y'
				AND F.IP_DataValidated = 1
				AND F.IP_ContactMechanismID IS NOT NULL 
				AND F.IP_OutletPartyID IS NOT NULL
			GROUP BY F.IP_OutletPartyID
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- 	ADD PARTY LANGUAGE IF ONE HAS BEEN SUPPLIED
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO Party.vwDA_PartyLanguages
			(
				AuditItemID, 
				PartyID,
				LanguageID, 
				FromDate,
				PreferredFlag
			)
			SELECT
				F.IP_AuditItemID,
				F.IP_OutletPartyID,
				F.IP_LanguageID,
				GETDATE() AS FromDate,
				1 AS PreferredFlag
			FROM DealerManagement.vwFranchises_Update F
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
				AND ISNULL(F.IP_LanguageID, 0) > 0
				AND F.Update_LocalLanguage = 'Y'
			GROUP BY F.IP_AuditItemID,
				F.IP_OutletPartyID,
				F.IP_LanguageID
			------------------------------------------------------------------------------------------------------------------------------		

					
			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE FIELDS IN DW_JLRCSPDEALERS TABLE (APART FROM DEALER NAME & DEALER CODE)
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D
			SET	D.SuperNationalRegion = RD.SuperNationalRegion,
				D.BusinessRegion = BR.BusinessRegionIpsos, 
				D.SubNationalTerritory = CASE	WHEN M.Market = 'United States of America' AND LEN(F.FranchiseRegion) > 0 THEN LTRIM(RTRIM(F.FranchiseRegion))	+ ' (' + M.FranchiseCountry + ')'		-- V1.5, V1.13
												WHEN M.Market = 'United States of America' AND LEN(F.FranchiseRegion) = 0 THEN ''																		-- V1.5, V1.13
												WHEN M.Market = 'China' AND LEN(F.FranchiseRegion) > 0 THEN LTRIM(RTRIM(F.FranchiseRegion)) + ' (' + M.FranchiseCountry + ')'							-- V1.8, V1.13
												WHEN M.Market = 'China' AND LEN(F.FranchiseRegion) = 0 THEN ''																							-- V1.8, V1.13
												WHEN M.Market IN ('Belgium','Luxembourg') THEN (M.DealerTableEquivMarket) + ' Territory' + ' (' + M.DealerTableEquivMarket + ')'						-- V1.16					
												ELSE COALESCE(M.DealerTableEquivMarket, M.Market) + ' Territory' + ' (' + M.FranchiseCountry + ')' END,					
				D.SubNationalRegion = CASE	WHEN F.FranchiseStatus = 'Terminated' THEN CASE	WHEN M.Market IN ('Belgium','Luxembourg') THEN 'Inactive' + ' (' + M.DealerTableEquivMarket + ')'		-- V1.16
																							ELSE 'Inactive' + ' (' + M.FranchiseCountry + ')' 
																							END																-- V1.7, V1.13, V1.16
											ELSE CASE	WHEN F.FranchiseCountry = 'USA' THEN F.FranchiseMarketNumber + ' (' + M.FranchiseCountry + ')'														-- V1.6, V1.13
														ELSE CASE	WHEN M.Market IN ('Belgium','Luxembourg') THEN CASE	WHEN FTOF.OutletFunction IN ('Aftersales') THEN COALESCE(AZ.SubNationalRegion, F.AuthorisedRepairerZone) + ' (' + M.DealerTableEquivMarket + ')'	-- V1.12, V1.13, V1.16
																														WHEN FTOF.OutletFunction IN ('Sales','PreOwned') THEN COALESCE(SZ.SubNationalRegion, F.SalesZone) + ' (' + M.DealerTableEquivMarket + ')'			-- V1.12, V1.13, V1.16
																														WHEN FTOF.OutletFunction IN ('Bodyshop') THEN BZ.SubNationalRegion + ' (' + M.DealerTableEquivMarket + ')'											-- V1.3, V1.13, V1.16
																														END
																	ELSE CASE	WHEN FTOF.OutletFunction IN ('Aftersales') THEN COALESCE(AZ.SubNationalRegion, F.AuthorisedRepairerZone) + ' (' + M.FranchiseCountry + ')'	-- V1.12, V1.13
																				WHEN FTOF.OutletFunction IN ('Sales','PreOwned') THEN COALESCE(SZ.SubNationalRegion, F.SalesZone) + ' (' + M.FranchiseCountry + ')'			-- V1.12, V1.13
																				WHEN FTOF.OutletFunction IN ('Bodyshop') THEN BZ.SubNationalRegion + ' (' + M.FranchiseCountry + ')'										-- V1.3, V1.13
																				END
																	END
														END		
											END,
				D.CombinedDealer = CASE WHEN M.Market NOT IN ('Belgium','Luxembourg') AND LEN(LTRIM(RTRIM(F.RetailerGroup))) > 0 THEN LTRIM(RTRIM(F.RetailerGroup)) + ' (' + M.FranchiseCountry + ')'
										WHEN M.Market IN ('Belgium','Luxembourg') AND LEN(LTRIM(RTRIM(F.RetailerGroup))) > 0 THEN LTRIM(RTRIM(F.RetailerGroup)) + ' (' + M.DealerTableEquivMarket + ')'
										WHEN LEN(LTRIM(RTRIM(F.RetailerGroup))) = 0 THEN ''
										END,  -- V1.17
				D.FromDate = COALESCE(F.FranchiseStartDate, GETDATE()),
				D.ThroughDate = CASE F.FranchiseStatus	WHEN 'Terminated' THEN F.FranchiseEndDate
														ELSE NULL END,											-- V1.9
				D.PAGCode = F.JLRNumber,
				D.PAGName = F.RetailerLocality,																	-- V1.10
				D.ChinaDMSRetailerCode = F.ChinaDMSRetailerCode,												-- V1.11
				D.SVODealer = CASE WHEN F.SVO = 'Yes' THEN 1 ELSE 0 END,	
				D.FleetDealer = CASE WHEN F.FleetandBusinessRetailer = 'Yes' THEN 1 ELSE 0 END,
				D.ApprovedUser = F.ApprovedUser																	-- V1.15
			FROM dbo.DW_JLRCSPDealers D
				INNER JOIN DealerManagement.vwFranchises_Update F ON D.Dealer10DigitCode = F.[10CharacterCode]
																	AND D.OutletPartyID = F.IP_OutletPartyID
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
																	AND D.OutletFunctionID = FTOF.OutletFunctionID
				INNER JOIN dbo.Markets M ON F.IP_CountryID = M.CountryID														-- V1.5 V1.19
				LEFT JOIN dbo.RDsRegions RD ON F.RDsRegionID = RD.RDsRegionID
				LEFT JOIN dbo.BusinessRegions BR ON F.BusinessRegionID = BR.BusinessRegionID
				LEFT JOIN dbo.SalesZones SZ ON F.SalesZoneID = SZ.SalesZoneID													-- V1.12
											AND F.IP_CountryID = SZ.CountryID
				LEFT JOIN dbo.AuthorisedRepairerZones AZ ON F.AuthorisedRepairerZoneID = AZ.AuthorisedRepairerZoneID			-- V1.12
														AND F.IP_CountryID = AZ.CountryID
				LEFT JOIN dbo.BodyShopZones BZ ON F.BodyshopZoneID = BZ.BodyshopZoneID											-- V1.3
												AND F.IP_CountryID = BZ.CountryID
			WHERE F.IP_ProcessedDate IS NULL		
				AND F.IP_DataValidated = 1
			------------------------------------------------------------------------------------------------------------------------------		
			
		
			------------------------------------------------------------------------------------------------------------------------------		
			-- V1.19 SET THROUGHDATE IN DEALERS TABLE TO GETDATE() WHERE OUTLETFUNCTION = PREOWNED AND APPROVEDUSER = NO
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE D 
			SET D.ThroughDate = GETDATE()
			FROM dbo.DW_JLRCSPDealers D
				INNER JOIN DealerManagement.vwFranchises_Update F ON D.Dealer10DigitCode = F.[10CharacterCode]
																	AND D.OutletPartyID = F.IP_OutletPartyID
				INNER JOIN dbo.FranchiseTypes FT ON F.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
																	AND D.OutletFunctionID = FTOF.OutletFunctionID			
			WHERE F.IP_DataValidated = 1
				AND FTOF.OutletFunction = 'PreOwned'
				AND F.ApprovedUser = 'No'
				AND D.ThroughDate IS NULL
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- V1.19 REMOVE FROM FRANCHISES TABLE WHERE OUTLETFUNCTION = PREOWNED AND APPROVEDUSER = NO
			------------------------------------------------------------------------------------------------------------------------------		
			DELETE FROM F
			FROM DealerManagement.vwFranchises_Update FU
				INNER JOIN dbo.FranchiseTypes FT ON FU.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.Franchises F ON FU.[10CharacterCode] = F.[10CharacterCode]
												AND FU.IP_CountryID = F.CountryID
												AND FU.IP_OutletPartyID = F.OutletPartyID
												AND FTOF.OutletFunctionID = F.OutletFunctionID
			WHERE FU.IP_DataValidated = 1
				AND F.OutletFunction = 'PreOwned'
				AND FU.ApprovedUser = 'No'
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- STAMP THE RECORDS AS PROCESSED
			------------------------------------------------------------------------------------------------------------------------------				
			UPDATE FL
			SET FL.IP_ProcessedDate = GETDATE()
			FROM DealerManagement.vwFranchises_Update F
				INNER JOIN DealerManagement.Franchises_Load FL ON F.IP_ID = FL.IP_ID
			WHERE F.IP_ProcessedDate IS NULL
				AND F.IP_DataValidated = 1
			------------------------------------------------------------------------------------------------------------------------------		
		

			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE FRANCHISE TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE F 
			SET F.ImportAuditItemID = FU.ImportAuditItemID,						-- V1.1
				F.ContactMechanismID = FU.IP_ContactMechanismID,
				F.LanguageID = FU.IP_LanguageID,								-- V1.14
				F.RDsRegionID = FU.RDsRegionID,
				F.BusinessRegionID = FU.BusinessRegionID,
				F.FranchiseRegionID = FU.FranchiseRegionID,
				F.FranchiseMarketID = FU.FranchiseMarketID,
				F.SalesZoneID = FU.SalesZoneID,
				F.AuthorisedRepairerZoneID = FU.AuthorisedRepairerZoneID,
				F.BodyshopZoneID = FU.BodyshopZoneID,
				F.RDsRegion = FU.RDsRegion,
				F.BusinessRegion = FU.BusinessRegion,
				F.DistributorCountryCode = FU.DistributorCountryCode,
				F.DistributorCountry = FU.DistributorCountry,
				F.DistributorCICode = FU.DistributorCICode,
				F.DistributorName = FU.DistributorName,
				F.FranchiseCountryCode = FU.FranchiseCountryCode,
				F.FranchiseCountry = FU.FranchiseCountry,
				F.JLRNumber = FU.JLRNumber,
				F.RetailerLocality = FU.RetailerLocality,
				F.Brand = FU.Brand,
				F.FranchiseCICode = ISNULL(FU.FranchiseCICode, ''),				-- V1.4
				F.FranchiseTradingTitle = FU.FranchiseTradingTitle,
				F.FranchiseShortName = FU.FranchiseShortName,
				F.RetailerGroup = FU.RetailerGroup,
				F.FranchiseType = FU.FranchiseType,
				F.Address1 = FU.Address1,
				F.Address2 = FU.Address2,
				F.Address3 = FU.Address3,
				F.AddressTown = FU.AddressTown,
				F.AddressCountyDistrict = FU.AddressCountyDistrict,
				F.AddressPostcode = FU.AddressPostcode,
				F.AddressLatitude = FU.AddressLatitude,
				F.AddressLongitude = FU.AddressLongitude,
				F.AddressActivity = FU.AddressActivity,
				F.Telephone = FU.Telephone,
				F.Email = FU.Email,
				F.URL = FU.URL,
				F.FranchiseStatus = FU.FranchiseStatus,
				F.FranchiseStartDate = FU.FranchiseStartDate,
				F.FranchiseEndDate = FU.FranchiseEndDate,
				F.LegacyFlag = FU.LegacyFlag,
				F.[10CharacterCode] = FU.[10CharacterCode],
				F.FleetandBusinessRetailer = FU.FleetandBusinessRetailer,
				F.SVO = FU.SVO,
				F.FranchiseMarket = FU.FranchiseMarket,
				F.FranchiseMarketNumber = FU.FranchiseMarketNumber,
				F.FranchiseRegion = FU.FranchiseRegion,
				F.FranchiseRegionNumber = FU.FranchiseRegionNumber,
				F.SalesZone = FU.SalesZone,
				F.SalesZoneCode = FU.SalesZoneCode,
				F.AuthorisedRepairerZone = FU.AuthorisedRepairerZone,
				F.AuthorisedRepairerZoneCode = FU.AuthorisedRepairerZoneCode,
				F.BodyshopZone = FU.BodyshopZone,
				F.BodyshopZoneCode = FU.BodyshopZoneCode,
				F.LocalTradingTitle1 = FU.LocalTradingTitle1,
				F.LocalLanguage1 = FU.LocalLanguage1,
				F.LocalTradingTitle2 = FU.LocalTradingTitle2,
				F.LocalLanguage2 = FU.LocalLanguage2,
				F.ChinaDMSRetailerCode = FU.ChinaDMSRetailerCode,			-- V1.11
				F.ApprovedUser = FU.ApprovedUser							-- V1.15
			FROM DealerManagement.vwFranchises_Update FU
				INNER JOIN dbo.FranchiseTypes FT ON FU.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.Franchises F ON FU.[10CharacterCode] = F.[10CharacterCode]
												AND FU.IP_CountryID = F.CountryID
												AND FU.IP_OutletPartyID = F.OutletPartyID
												AND FTOF.OutletFunctionID = F.OutletFunctionID
			WHERE FU.IP_DataValidated = 1
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- REBUILD FLATTENED DEALER TABLE 
			EXEC [$(ETLDB)].DealerManagement.uspDEALERS_JLRCSP_CreateFlatDealerList
			------------------------------------------------------------------------------------------------------------------------------		
			
			COMMIT TRANSACTION
	
	END TRY

	BEGIN CATCH

		SET @ErrorCode = @@Error

		SELECT
			 @ErrorNumber = Error_Number()
			,@ErrorSeverity = Error_Severity()
			,@ErrorState = Error_State()
			,@ErrorLocation = Error_Procedure()
			,@ErrorLine = Error_Line()
			,@ErrorMessage = Error_Message()

		EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
			 @ErrorNumber
			,@ErrorSeverity
			,@ErrorState
			,@ErrorLocation
			,@ErrorLine
			,@ErrorMessage
			
		RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
			
	END CATCH
GO