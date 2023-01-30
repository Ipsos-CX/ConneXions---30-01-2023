CREATE PROCEDURE [DealerManagement].[uspAddFranchises]

AS

SET NOCOUNT ON

/*

Release		Version		Created			Author			Description	
-------		-------		------			-------			
LIVE		1.0			2021-01-08		Chris Ledger	Created from Sample_ETL.DealerManagement.uspDEALERS_JLRCSP_DoAppointments
LIVE		1.1			2021-01-13		Chris Ledger	Change references from RetailerCode to 10CharacterCode
LIVE		1.2			2021-01-19		Chris Ledger	Incorporate Region/Zones
LIVE		1.3			2021-01-28		Chris Ledger	Add Auditing of Franchises_Load table
LIVE		1.4			2021-01-29		Chris Ledger	Extend auditing
LIVE		1.5			2021-02-02		Chris Ledger	Remove check on active dealers when matching OutletPartyID
LIVE		1.6			2021-02-02		Chris Ledger	Add check on exiting entries in Franchises & DW_JLRCSPDealers tables
LIVE		1.7			2021-02-04		Chris Ledger	Change coding of SubNationalRegion for Bodyshop
LIVE		1.8			2021-05-10		Chris Ledger	Change coding of SubNationalRegion to Market Number for US
LIVE		1.9			2021-05-10		Chris Ledger	Change coding of SubNationalTerritory to Market + ' Territory' for non US markets
LIVE		1.10		2021-05-25		Ben King		TASK 464 - Historic data  Hierarchy file - terminated retailers
LIVE		1.11		2021-06-22		Chris Ledger	TASK 472 - Add UseLatestName to INSERT INTO Party.vwDA_LegalOrganisations
LIVE		1.12		2021-06-23		Chris Ledger	TASK 517 - China Region update
LIVE		1.13		2021-07-16		Chris Ledger	TASK 556 - Only set Through Date for terminated dealers
LIVE		1.14        2021-08-12      Ben King        TASK 577 - PAGName to be filled in using FIMs Retailer Locality field
LIVE		1.15        2021-08-17      Ben King        TASK 578 - China 3 digit code
LIVE		1.16		2021-11-10		Chris Ledger	TASK 692 - Change coding of SubNationalRegion for Sales,PreOwned & AfterSales to use SubNationalRegion if available 
LIVE		1.17        2021-12-13      Ben King        TASK 722 - Region and Sub National Territory naming 
LIVE		1.18		2022-01-06		Chris Ledger	TASK 579 - Add LanguageID
LIVE		1.19		2022-01-17		Chris Ledger	TASK 751 - Add ApprovedUser
LIVE		1.20		2022-01-20		Chris Ledger	TASK 728 - Change JOIN on Markets table
LIVE		1.21		2022-03-03		Chris Ledger	TASK 722 - Set Belgium & Luxembourg SubNational/SubNationalTerritory to BELUX
LIVE        1.22        2022-03-28      Ben King        TASK 838 - 19473 - Hierarchy - Dealer Group naming

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
				ImportAuditItemID				INT,		-- V1.3
				LoadType						CHAR(1)		-- V1.4
			)

			INSERT INTO #AuditTrail
			(
				ID,
				IP_ID,
				AuditID,
				AuditItemID,
				ImportAuditItemID,							-- V1.3
				LoadType									-- V1.4
			)
			SELECT 
				ROW_NUMBER() OVER (ORDER BY IP_ID) ID,
				FN.IP_ID,
				NULL AS AuditID,
				NULL AS AuditItemID,
				FN.ImportAuditItemID,						-- V1.3
				'A' AS LoadType								-- V1.4
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_ProcessedDate IS NULL
			AND FN.IP_DataValidated = 1
		
			SELECT @RecsToUpdate = COUNT(*), @FileName = FN.ImportFileName 
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_ProcessedDate IS NULL
			AND FN.IP_DataValidated = 1
			GROUP BY FN.ImportFileName
		
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
				'Add New Franchises: ' + @FileName AS FileName,
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

			INSERT INTO [$(AuditDB)].Audit.Franchises_Load		-- V1.3
			(	AuditItemID,
				ImportAuditItemID
			)
			SELECT
				AuditItemID,
				ImportAuditItemID
			FROM #AuditTrail
			------------------------------------------------------------------------------------------------------------------------------		
				
				
			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE AUDITITEMIDS BACK TO FRANCHISE_LOAD TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE FN
			SET IP_AuditItemID = AT.AuditItemID
			FROM #AuditTrail AT
			INNER JOIN DealerManagement.vwFranchises_New FN ON AT.IP_ID = FN.IP_ID
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- ASSIGN PARENT ORGANISATION AUDITITEMID IN DEALER APPOINTMENT TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE FN
			SET IP_OrganisationParentAuditItemID = OPAD.IP_OrganisationParentAuditItemID
			FROM DealerManagement.vwFranchises_New FN
			INNER JOIN
				(	SELECT 
						FN.IP_CountryID,
						FN.[10CharacterCode],
						MIN(FN.IP_AuditItemID) AS IP_OrganisationParentAuditItemID
					FROM DealerManagement.vwFranchises_New FN 
					WHERE FN.IP_ProcessedDate IS NULL
						AND FN.IP_DataValidated = 1
					GROUP BY FN.IP_CountryID, 
						FN.[10CharacterCode]) OPAD ON FN.[10CharacterCode] = OPAD.[10CharacterCode]
													AND FN.IP_CountryID = OPAD.IP_CountryID
													AND FN.IP_ProcessedDate IS NULL
													AND FN.IP_DataValidated = 1	
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------
			-- UPDATE IP_OutletPartyID AND ContactMechanismID TO EXISTING PartyID IF DEALER ALREADY EXISTS
			-- USE EXISTING PARTYID OF LOWEST OutletFunctionID (I.E. SALES THEN SERVICE THEN PREOWNED) 
			-- ASSIGNS IP_OutletPartyID SO NEW ORGANISATIONS AREN'T ADDED
			-- AND ContactMechanismID SO NEW POSTAL ADDRESS 
			------------------------------------------------------------------------------------------------------------------------------		
			--SELECT F.OutletPartyID, F.ContactMechanismID, FN.*
			UPDATE FN 
			SET	FN.IP_OutletPartyID = F.OutletPartyID, 
				FN.IP_ContactMechanismID = F.ContactMechanismID
			FROM dbo.Franchises F
			INNER JOIN 
				(	SELECT MIN(F.OutletFunctionID) AS OutletFunctionID,
						FN.[10CharacterCode],
						FN.IP_CountryID
					FROM DealerManagement.vwFranchises_New FN
						INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
						INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
						INNER JOIN dbo.Franchises F ON FN.IP_OutletPartyID = F.OutletPartyID
													AND FTOF.OutletFunctionID = F.OutletFunctionID
					WHERE FN.IP_DataValidated = 1
						AND FN.IP_ProcessedDate IS NULL										-- V1.5	
						--AND F.FranchiseEndDate IS NULL			-- ONLY GET ACTIVE DEALERS V1.5
					GROUP BY FN.[10CharacterCode], 
						FN.IP_CountryID) ED ON F.[10CharacterCode] = ED.[10CharacterCode]
											AND F.CountryID = ED.IP_CountryID
											AND F.OutletFunctionID = ED.OutletFunctionID
			INNER JOIN DealerManagement.vwFranchises_New FN ON FN.[10CharacterCode] = F.[10CharacterCode]
																AND FN.IP_CountryID = F.CountryID
			WHERE FN.IP_DataValidated = 1
				AND FN.IP_ProcessedDate IS NULL
			------------------------------------------------------------------------------------------------------------------------------
			
		
			------------------------------------------------------------------------------------------------------------------------------
			-- WRITE ORGANISATIONS (I.E. DEALERS) INTO SAMPLE MODEL
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO Party.vwDA_LegalOrganisations			
			(
				AuditItemID,
				ParentAuditItemID,
				PartyID,
				FromDate,
				OrganisationName,
				LegalName,
				UseLatestName							-- V1.11
			)
			SELECT 
				FN.IP_AuditItemID AS AuditItemID,
				FN.IP_OrganisationParentAuditItemID AS ParentAuditItemID,
				ISNULL(FN.IP_OutletPartyID, 0) AS PartyID,
				COALESCE(FN.FranchiseStartDate,GETDATE()) AS FromDate,
				FN.FranchiseTradingTitle AS OrganisationName,
				FN.FranchiseTradingTitle AS LegalName,
				0 AS UseLatestName						-- V1.11
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_DataValidated = 1
				AND FN.IP_OutletPartyID IS NULL
				AND FN.IP_ProcessedDate IS NULL
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------				
			-- WRITE NEWLY CREATED DEALERS PARTYID BACK TO FRANCHISE_LOAD TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE FN 
			SET FN.IP_OutletPartyID = AO.PartyID
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN [$(AuditDB)].Audit.Organisations AO ON FN.IP_AuditItemID = AO.AuditItemID
			WHERE FN.IP_ProcessedDate IS NULL 
				AND FN.IP_DataValidated = 1
			------------------------------------------------------------------------------------------------------------------------------			


			------------------------------------------------------------------------------------------------------------------------------		
			-- ORGANISATION PARTIES NOW CREATED SO LETS NOW LOAD THESE PARTIES AS DEALERS
			------------------------------------------------------------------------------------------------------------------------------		

			------------------------------------------------------------------------------------------------------------------------------		
			-- UPDATE @ImporterPartyID BASED ON vwBrandMarketQuestionnaireSampleMetadata VALUE
			UPDATE FN 
			SET FN.IP_ImporterPartyID = SM.DealerCodeOriginatorPartyID 
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.Questionnaires Q ON FTOF.QuestionnaireID = Q.QuestionnaireID
				LEFT JOIN dbo.Markets M ON FN.IP_CountryID = M.CountryID										-- V1.20
				LEFT JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON M.Market = SM.Market
																			AND FN.Brand = SM.Brand
																			AND Q.Questionnaire = SM.Questionnaire
																			AND SM.SampleLoadActive = 1
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) > 0
				AND ISNULL(SM.DealerCodeOriginatorPartyID, 0) NOT IN (2,3)
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- INSERT DEALER NETWORKS RELATIONSHIPS - USE THE LOCAL LANGAUGE NAME FOR THE DEALER NAME COLUMN
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO Party.vwDA_DealerNetworks
			(
				AuditItemID, 
				PartyIDFrom, 
				PartyIDTo, 
				RoleTypeIDFrom, 
				RoleTypeIDTo, 
				DealerCode, 
				DealerShortName, 
				FromDate 
			)
			SELECT
				FN.IP_AuditItemID,
				FN.IP_OutletPartyID AS PartyIDFrom, 
				FN.IP_ImporterPartyID AS PartyIDTo, 
				FTOF.OutletFunctionID AS RoleTypeIDFrom, 
				19 AS RoleTypeIDTo, 
				ISNULL(FN.FranchiseCICode, '') AS DealerCode, 
				FN.FranchiseTradingTitle AS DealerShortName, 
				COALESCE(FN.FranchiseStartDate,GETDATE()) AS FromDate
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND NULLIF(FN.IP_ImporterPartyID, 0) > 0
				AND ((FTOF.OutletFunction = 'PreOwned' AND ISNULL(FN.ApprovedUser,'') <> 'No') OR FTOF.OutletFunction <> 'PreOwned')	-- V1.19 Only add 'PreOwned' FranchiseType if ApprovedUser = 'NO'
			UNION
			-- LOAD VEHICLE MANUFACTURER RELATIONSHIPS WITH OUTLETS (STANDARD CODES)
			SELECT
				FN.IP_AuditItemID, 
				FN.IP_OutletPartyID AS PartyIDFrom,
				FN.IP_ManufacturerPartyID AS PartyIDTo, 
				FTOF.OutletFunctionID AS RoleTypeIDFrom, 
				7 AS RoleTypeIDTo, 
				ISNULL(FN.FranchiseCICode, '') AS DealerCode, 
				FN.FranchiseTradingTitle AS DealerShortName, 
				COALESCE(FN.FranchiseStartDate,GETDATE()) AS FromDate
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND FN.IP_ManufacturerPartyID IS NOT NULL
				AND ((FTOF.OutletFunction = 'PreOwned' AND ISNULL(FN.ApprovedUser,'') <> 'No') OR FTOF.OutletFunction <> 'PreOwned')	-- V1.19 Only add 'PreOwned' FranchiseType if ApprovedUser = 'NO'
			------------------------------------------------------------------------------------------------------------------------------		

			
			------------------------------------------------------------------------------------------------------------------------------		
			-- ASSIGN PARENT POSTAL ADDRESS AUDITITEMID IN DEALER APPOINTMENT TABLE
			------------------------------------------------------------------------------------------------------------------------------					
			UPDATE FN
			SET FN.IP_AddressParentAuditItemID = P.AddressParentAuditItemID
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN (	SELECT
									'' AS BuildingName,
									'' AS SubStreetNumber, 
									'' AS SubStreet, 
									'' AS StreetNumber, 
									COALESCE(FN.Address1, '') AS Street, 
									COALESCE(FN.Address2, '') AS SubLocality, 
									COALESCE(FN.Address3, '') AS Locality, 
									COALESCE(FN.AddressTown, '') AS Town, 
									COALESCE(FN.AddressCountyDistrict, '') AS Region, 
									COALESCE(FN.AddressPostcode, '') AS PostCode, 
									FN.IP_CountryID AS CountryID, 
									MIN(FN.IP_AuditItemID) AS AddressParentAuditItemID
								FROM DealerManagement.vwFranchises_New FN
								WHERE FN.IP_ProcessedDate IS NULL
									AND FN.IP_DataValidated = 1
									AND FN.IP_ContactMechanismID IS NULL
								GROUP BY
									COALESCE(FN.Address1, ''), 
									COALESCE(FN.Address2, ''), 
									COALESCE(FN.Address3, ''), 
									COALESCE(FN.AddressTown, ''), 
									COALESCE(FN.AddressCountyDistrict, ''), 
									COALESCE(FN.AddressPostcode, ''), 
									FN.IP_CountryID ) P ON P.Street = COALESCE(FN.Address1, '')
														AND P.SubLocality = COALESCE(FN.Address2, '')
														AND P.Locality = COALESCE(FN.Address3, '')
														AND P.Town = COALESCE(FN.AddressTown, '')
														AND P.Region = COALESCE(FN.AddressCountyDistrict, '')
														AND P.PostCode = COALESCE(FN.AddressPostCode, '')
														AND P.CountryID = FN.IP_CountryID
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND FN.IP_ContactMechanismID IS NULL
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
			SELECT
				FN.IP_AuditItemID,
				FN.IP_AddressParentAuditItemID,
				0 AS ContactMechanismID, 
				1 AS ContactMechanismTypeID,	-- Postal address
				'' AS BuildingName,
				'' AS SubStreetNumber, 
				'' AS SubStreet, 
				'' AS StreetNumber, 
				COALESCE(FN.Address1, '') AS Street, 
				COALESCE(FN.Address2, '') AS SubLocality, 
				COALESCE(FN.Address3, '') AS Locality, 
				COALESCE(FN.AddressTown, '') AS Town, 
				COALESCE(FN.AddressCountyDistrict, '') AS Region, 
				COALESCE(FN.AddressPostcode, '') AS PostCode, 
				FN.IP_CountryID AS CountryID,
				0 AS AddressChecksum
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND NULLIF(FN.IP_ContactMechanismID, 0) IS NULL
				AND ISNULL(FN.IP_CountryID, 0) > 0
			------------------------------------------------------------------------------------------------------------------------------		

		
			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE CONTACTMECHANISM BACK TO DEALER APPOINTMENT TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			UPDATE FN
			SET FN.IP_ContactMechanismID = APA.ContactMechanismID
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON FN.IP_AuditItemID = APA.AuditItemID
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND NULLIF(FN.IP_ContactMechanismID, 0) IS NULL
				AND ISNULL(FN.IP_CountryID, 0) > 0
			------------------------------------------------------------------------------------------------------------------------------		
			

			------------------------------------------------------------------------------------------------------------------------------		
			-- WRITE PARTYPOSTALADDDRESSES (I.E. TIE NEW DEALERS TO THEIR ADDRESSES)
			------------------------------------------------------------------------------------------------------------------------------		
			;WITH CTE_MinDate (IP_ContactMechanism, IP_OutletPartyID, FromDate) AS
			(			
				SELECT 
					FN.IP_ContactMechanismID, 
					FN.IP_OutletPartyID, 
					MIN(COALESCE(FN.FranchiseStartDate,GETDATE())) AS FromDate
				FROM DealerManagement.vwFranchises_New FN
				WHERE FN.IP_ProcessedDate IS NULL
					AND FN.IP_DataValidated = 1
					AND FN.IP_ContactMechanismID IS NOT NULL 
					AND FN.IP_OutletPartyID IS NOT NULL
					AND FN.IP_AddressParentAuditItemID IS NOT NULL	-- V1.7 ONLY ADD IF NEW CONTACT MECHANISM
				GROUP BY FN.IP_ContactMechanismID, FN.IP_OutletPartyID
			)
			INSERT INTO ContactMechanism.vwDA_PartyPostalAddresses
			(
				AuditItemID, 
				ContactMechanismID, 
				PartyID, 
				FromDate, 
				ContactMechanismPurposeTypeID
			)
			SELECT
				FN.IP_AuditItemID,
				FN.IP_ContactMechanismID, 
				FN.IP_OutletPartyID, 
				C.FromDate AS FromDate,
				2 AS ContactMechanismPurposeTypeID					-- Main business address
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN CTE_MinDate C ON FN.IP_ContactMechanismID = C.IP_ContactMechanism
											AND FN.IP_OutletPartyID = C.IP_OutletPartyID
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
				FN.IP_AuditItemID,
				FN.IP_OutletPartyID,
				FN.IP_LanguageID,
				COALESCE(FN.FranchiseStartDate,GETDATE()) AS FromDate,
				1 AS PreferredFlag
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND ISNULL(FN.IP_LanguageID, 0) > 0
			------------------------------------------------------------------------------------------------------------------------------		

					
			------------------------------------------------------------------------------------------------------------------------------		
			-- INSERT INTO DW_JLRCSPDEALERS TABLE
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO dbo.DW_JLRCSPDealers
			(
				Manufacturer, 
				SuperNationalRegion, 
				BusinessRegion,
				Market, 
				SubNationalTerritory,
				SubNationalRegion, 
				CombinedDealer,
				TransferDealer, 
				TransferDealerCode, 
				Outlet, 
				OutletCode, 
				OutletFunction, 
				ManufacturerPartyID, 
				MarketPartyID, 
				TransferPartyID, 
				OutletPartyID, 
				OutletLevelReport, 
				OutletLevelWeb, 
				OutletFunctionID, 
				OutletSiteCode, 
				FromDate,
				ThroughDate,
				OutletCode_GDD,
				PAGCode,
				PAGName,
				SVODealer,						
				FleetDealer,
				Dealer10DigitCode,
				ChinaDMSRetailerCode,	-- V1.15
				ApprovedUser			-- V1.19
			)
			SELECT
				FN.Brand, 		
				RD.SuperNationalRegion AS SuperNationalRegion,
				BR.BusinessRegionIpsos AS BusinessRegion, 
				COALESCE(M.DealerTableEquivMarket, M.Market) AS Market, 
				CASE	WHEN M.Market = 'United States of America' THEN LTRIM(RTRIM(FN.FranchiseRegion)) + ' (' + M.FranchiseCountry + ')'					-- V1.8, V1.17
						WHEN M.Market = 'United States of America' AND LEN(FN.FranchiseRegion) > = 0 THEN ''                                                -- V1.8, V1.17
						WHEN M.Market = 'China' THEN LTRIM(RTRIM(FN.FranchiseRegion)) + ' (' + M.FranchiseCountry + ')'										-- V1.11, V1.17
						WHEN M.Market = 'China' AND LEN(FN.FranchiseRegion) = 0 THEN ''                                                                     -- V1.11, V1.17
						WHEN M.Market IN ('Belgium','Luxembourg') THEN (M.DealerTableEquivMarket) + ' Territory' + ' (' + M.DealerTableEquivMarket + ')'	-- V1.21
						ELSE COALESCE(M.DealerTableEquivMarket, M.Market) + ' Territory' + ' (' + M.FranchiseCountry + ')' END AS SubNationalTerritory,		-- V1.17
				CASE	WHEN FN.FranchiseStatus = 'Terminated' THEN CASE	WHEN M.Market IN ('Belgium','Luxembourg') THEN 'Inactive' + ' (' + M.DealerTableEquivMarket + ')'	-- V1.21
																			ELSE 'Inactive' + ' (' + M.FranchiseCountry + ')'													-- V1.10, V1.17
																	END
						ELSE CASE	WHEN M.Market = 'United States of America' THEN FN.FranchiseMarketNumber + ' (' + M.FranchiseCountry + ')'									-- V1.17	
									ELSE CASE	WHEN M.Market IN ('Belgium','Luxembourg') THEN CASE	WHEN FTOF.OutletFunction IN ('Aftersales') THEN COALESCE(AZ.SubNationalRegion, FN.AuthorisedRepairerZone) + ' (' + M.DealerTableEquivMarket + ')'	-- V1.16, V1.17, V1.21
																									WHEN FTOF.OutletFunction IN ('Sales','PreOwned') THEN COALESCE(SZ.SubNationalRegion, FN.SalesZone) + ' (' + M.DealerTableEquivMarket + ')'			-- V1.16, V1.17, V1.21
																									WHEN FTOF.OutletFunction IN ('Bodyshop') THEN BZ.SubNationalRegion	+ ' (' + M.DealerTableEquivMarket + ')'											-- V1.7, V1.17, V1.21
																									END
												ELSE CASE	WHEN FTOF.OutletFunction IN ('Aftersales') THEN COALESCE(AZ.SubNationalRegion, FN.AuthorisedRepairerZone) + ' (' + M.FranchiseCountry + ')'		-- V1.16, V1.17
															WHEN FTOF.OutletFunction IN ('Sales','PreOwned') THEN COALESCE(SZ.SubNationalRegion, FN.SalesZone) + ' (' + M.FranchiseCountry + ')'			-- V1.16, V1.17
															WHEN FTOF.OutletFunction IN ('Bodyshop') THEN BZ.SubNationalRegion	+ ' (' + M.FranchiseCountry + ')'											-- V1.7, V1.17
															END
												END
									END
						END AS SubNationalRegion, 
				CASE WHEN M.Market NOT IN ('Belgium','Luxembourg') AND LEN(LTRIM(RTRIM(FN.RetailerGroup))) > 0 THEN LTRIM(RTRIM(FN.RetailerGroup)) + ' (' + M.FranchiseCountry + ')' 
				     WHEN M.Market IN ('Belgium','Luxembourg') AND LEN(LTRIM(RTRIM(FN.RetailerGroup))) > 0 THEN LTRIM(RTRIM(FN.RetailerGroup)) + ' (' + M.DealerTableEquivMarket + ')' 
					 WHEN LEN(LTRIM(RTRIM(FN.RetailerGroup))) = 0 THEN ''
					 END AS CombinedDealer,		-- V1.22
				LTRIM(RTRIM(FN.FranchiseTradingTitle)) AS TransferDealer,
				LTRIM(RTRIM(FN.FranchiseCICode)) AS TransferDealerCode, 
				FN.FranchiseTradingTitle AS OutletName,
				FN.FranchiseCICode AS OutletCode,
				FTOF.OutletFunction,
				FN.IP_ManufacturerPartyID AS ManufacturerPartyID, 
				0 AS MarketPartyID, 
				FN.IP_OutletPartyID AS TransferPartyID, 
				FN.IP_OutletPartyID AS OutletPartyID, 
				1 AS OutletLevelReport, 
				1 AS OutletLevelWeb, 
				FTOF.OutletFunctionID AS OutletFunctionID,
				'' AS OutletSiteCode,
				COALESCE(FN.FranchiseStartDate,GETDATE()) AS FromDate,
				CASE FN.FranchiseStatus	WHEN 'Terminated' THEN FN.FranchiseEndDate
										ELSE NULL END AS ThroughDate,									-- V1.13
				'' AS OutletCode_GDD,
				FN.JLRNumber AS PAGCode,
				FN.RetailerLocality AS PAGName,															-- V1.14
				CASE WHEN FN.SVO = 'Yes' THEN 1 ELSE 0 END AS SVODealer,	
				CASE WHEN FN.FleetandBusinessRetailer = 'Yes' THEN 1 ELSE 0 END AS FleetDealer,
				FN.[10CharacterCode] AS Dealer10DigitCode,
				FN.ChinaDMSRetailerCode,																-- V1.15
				FN.ApprovedUser																			-- V1.19
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
				INNER JOIN dbo.Markets M ON FN.IP_CountryID = M.CountryID												-- V1.19
				LEFT JOIN dbo.RDsRegions RD ON FN.RDsRegionID = RD.RDsRegionID
				LEFT JOIN dbo.BusinessRegions BR ON FN.BusinessRegionID = BR.BusinessRegionID
				LEFT JOIN dbo.SalesZones SZ ON FN.SalesZoneID = SZ.SalesZoneID											-- V1.16
													AND FN.IP_CountryID = SZ.CountryID
				LEFT JOIN dbo.AuthorisedRepairerZones AZ ON FN.AuthorisedRepairerZoneID = AZ.AuthorisedRepairerZoneID	-- V1.16
													AND FN.IP_CountryID = AZ.CountryID
				LEFT JOIN dbo.BodyShopZones BZ ON FN.BodyshopZoneID = BZ.BodyshopZoneID									-- V1.7
													AND FN.IP_CountryID = BZ.CountryID
			WHERE FN.IP_ProcessedDate IS NULL		
				AND FN.IP_DataValidated = 1
				AND ((FTOF.OutletFunction = 'PreOwned' AND ISNULL(FN.ApprovedUser,'') <> 'No') OR FTOF.OutletFunction <> 'PreOwned')	-- V1.19 Only add 'PreOwned' FranchiseType if ApprovedUser = 'NO'
				AND NOT EXISTS (	SELECT *																			-- V1.6
									FROM dbo.DW_JLRCSPDealers D
									WHERE D.OutletPartyID = FN.IP_OutletPartyID
										AND D.OutletFunctionID = FTOF.OutletFunctionID)
			------------------------------------------------------------------------------------------------------------------------------		

			
			------------------------------------------------------------------------------------------------------------------------------		
			-- V1.19 UPDATE PREOWNED THROUGHDATE (PREOWNED RECORD ADDED BECAUSE APPROVEDUSER CHANGED FROM NO TO YES BUT ALREADY EXISTS IN DEALERS TABLE) 
			UPDATE D
			SET D.ThroughDate = FN.FranchiseEndDate
			FROM dbo.DW_JLRCSPDealers D 
				INNER JOIN DealerManagement.vwFranchises_New FN ON FN.IP_OutletPartyID = D.OutletPartyID
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
																	AND D.OutletFunctionID = FTOF.OutletFunctionID
			WHERE ISNULL(D.ApprovedUser,'') <> ISNULL(FN.ApprovedUser,'')
				AND FN.ApprovedUser = 'Yes'
				AND ISNULL(D.ThroughDate,'2099-01-01') <> ISNULL(FN.FranchiseEndDate,'2099-01-01')
			------------------------------------------------------------------------------------------------------------------------------		


			------------------------------------------------------------------------------------------------------------------------------		
			-- V1.19 UPDATE ALL APPROVEDUSER (PREOWNED RECORD ADDED BECAUSE APPROVEDUSER CHANGED FROM NO TO YES BUT ALREADY EXISTS IN DEALERS TABLE)
			UPDATE D
			SET D.ApprovedUser = FN.ApprovedUser
			FROM dbo.DW_JLRCSPDealers D 
				INNER JOIN DealerManagement.vwFranchises_New FN ON FN.IP_OutletPartyID = D.OutletPartyID
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
																	AND D.OutletFunctionID = FTOF.OutletFunctionID
			WHERE ISNULL(D.ApprovedUser,'') <> ISNULL(FN.ApprovedUser,'')
			------------------------------------------------------------------------------------------------------------------------------		

					
			------------------------------------------------------------------------------------------------------------------------------		
			-- INSERT RECORDS INTO TABLE CONTACTMECHANISM.DEALERCOUNTRIES
			------------------------------------------------------------------------------------------------------------------------------		
			INSERT INTO ContactMechanism.DealerCountries
			SELECT DISTINCT 
				FN.IP_OutletPartyID,
				DN.PartyIDTo,
				DN.RoleTypeIDFrom,
				DN.RoleTypeIDTo,
				DN.DealerCode,
				FN.IP_CountryID 
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN Party.DealerNetworks DN ON FN.IP_OutletPartyID = DN.PartyIDFrom
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
				AND NOT EXISTS (	SELECT * FROM ContactMechanism.DealerCountries DC		-- WHERE ROW DOESN'T ALREADY EXIST
									WHERE DC.PartyIDFrom = DN.PartyIDFrom 
										AND DC.PartyIDTo = DN.PartyIDTo 
										AND DC.RoleTypeIDFrom = DN.RoleTypeIDFrom 
										AND DC.RoleTypeIDTo = DN.RoleTypeIDTo)
			------------------------------------------------------------------------------------------------------------------------------		
				
		
			------------------------------------------------------------------------------------------------------------------------------		
			-- STAMP THE RECORDS AS PROCESSES
			------------------------------------------------------------------------------------------------------------------------------				
			UPDATE FN
			SET FN.IP_ProcessedDate = GETDATE()
			FROM DealerManagement.vwFranchises_New FN
			WHERE FN.IP_ProcessedDate IS NULL
				AND FN.IP_DataValidated = 1
			------------------------------------------------------------------------------------------------------------------------------		
		

			------------------------------------------------------------------------------------------------------------------------------		
			-- INSERT INTO FRANCHISE TABLE
			INSERT INTO dbo.Franchises
			(
				OutletFunctionID, 
				OutletFunction,
				OutletPartyID,
				ContactMechanismID, 
				ManufacturerPartyID,
				LanguageID,							-- V1.18
				CountryID, 
				ImporterPartyID,					-- V1.3
				ImportAuditItemID,					-- V1.3
				RDsRegionID, 
				BusinessRegionID, 
				FranchiseRegionID,					-- V1.2
				FranchiseMarketID,					-- V1.2
				SalesZoneID,						-- V1.2
				AuthorisedRepairerZoneID,			-- V1.2
				BodyshopZoneID,						-- V1.2
				RDsRegion, 
				BusinessRegion, 
				DistributorCountryCode, 
				DistributorCountry, 
				DistributorCICode, 
				DistributorName, 
				FranchiseCountryCode, 
				FranchiseCountry, 
				JLRNumber, 
				RetailerLocality, 
				Brand, 
				FranchiseCICode, 
				FranchiseTradingTitle, 
				FranchiseShortName, 
				RetailerGroup, 
				FranchiseType, 
				Address1, 
				Address2, 
				Address3, 
				AddressTown, 
				AddressCountyDistrict, 
				AddressPostcode, 
				AddressLatitude, 
				AddressLongitude, 
				AddressActivity, 
				Telephone, 
				Email, 
				URL, 
				FranchiseStatus, 
				FranchiseStartDate, 
				FranchiseEndDate, 
				LegacyFlag, 
				[10CharacterCode], 
				FleetandBusinessRetailer, 
				SVO, 
				FranchiseMarket, 					-- V1.2
				FranchiseMarketNumber, 				-- V1.2
				FranchiseRegion, 					-- V1.2
				FranchiseRegionNumber, 				-- V1.2
				SalesZone, 
				SalesZoneCode,
				AuthorisedRepairerZone, 
				AuthorisedRepairerZoneCode, 
				BodyshopZone, 
				BodyshopZoneCode, 
				LocalTradingTitle1, 
				LocalLanguage1, 
				LocalTradingTitle2, 
				LocalLanguage2,
				ChinaDMSRetailerCode,				-- V1.15
				ApprovedUser						-- V1.19
			)
			SELECT FTOF.OutletFunctionID, 
				FTOF.OutletFunction,
				FN.IP_OutletPartyID,
				FN.IP_ContactMechanismID,
				FN.IP_ManufacturerPartyID, 
				FN.IP_LanguageID,					-- V1.18
				FN.IP_CountryID,
				FN.IP_ImporterPartyID,				-- V1.3
				FN.ImportAuditItemID,				-- V1.3
				FN.RDsRegionID,						-- V1.2
				FN.BusinessRegionID,				-- V1.2 
				FN.FranchiseRegionID,				-- V1.2
				FN.FranchiseMarketID,				-- V1.2
				FN.SalesZoneID,						-- V1.2
				FN.AuthorisedRepairerZoneID,		-- V1.2
				FN.BodyshopZoneID,					-- V1.2
				FN.RDsRegion,
				FN.BusinessRegion, 
				FN.DistributorCountryCode, 
				FN.DistributorCountry, 
				FN.DistributorCICode, 
				FN.DistributorName, 
				FN.FranchiseCountryCode, 
				FN.FranchiseCountry, 
				FN.JLRNumber, 
				FN.RetailerLocality, 
				FN.Brand, 
				FN.FranchiseCICode, 
				FN.FranchiseTradingTitle, 
				FN.FranchiseShortName, 
				FN.RetailerGroup, 
				FN.FranchiseType, 
				FN.Address1, 
				FN.Address2, 
				FN.Address3, 
				FN.AddressTown, 
				FN.AddressCountyDistrict, 
				FN.AddressPostcode, 
				FN.AddressLatitude, 
				FN.AddressLongitude, 
				FN.AddressActivity, 
				FN.Telephone, 
				FN.Email, 
				FN.URL, 
				FN.FranchiseStatus, 
				FN.FranchiseStartDate, 
				FN.FranchiseEndDate, 
				FN.LegacyFlag, 
				FN.[10CharacterCode], 
				FN.FleetandBusinessRetailer, 
				FN.SVO, 
				FN.FranchiseMarket,					-- V1.2
				FN.FranchiseMarketNumber,			-- V1.2
				FN.FranchiseRegion,					-- V1.2
				FN.FranchiseRegionNumber,			-- V1.2
				FN.SalesZone, 
				FN.SalesZoneCode, 
				FN.AuthorisedRepairerZone, 
				FN.AuthorisedRepairerZoneCode, 
				FN.BodyshopZone, 
				FN.BodyshopZoneCode, 
				FN.LocalTradingTitle1, 
				FN.LocalLanguage1, 
				FN.LocalTradingTitle2, 
				FN.LocalLanguage2,
				FN.ChinaDMSRetailerCode,			-- V1.15
				FN.ApprovedUser						-- V1.19
			FROM DealerManagement.vwFranchises_New FN
				INNER JOIN dbo.FranchiseTypes FT ON FN.FranchiseType = FT.FranchiseType
				INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
			WHERE ((FTOF.OutletFunction = 'PreOwned' AND ISNULL(FN.ApprovedUser,'') <> 'No') OR FTOF.OutletFunction <> 'PreOwned')	-- V1.19 Only add 'PreOwned' FranchiseType if ApprovedUser = 'NO'
				AND	NOT EXISTS (	SELECT *			-- V1.6
									FROM dbo.Franchises F
									WHERE F.OutletPartyID = FN.IP_OutletPartyID
										AND F.OutletFunctionID = FTOF.OutletFunctionID)
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