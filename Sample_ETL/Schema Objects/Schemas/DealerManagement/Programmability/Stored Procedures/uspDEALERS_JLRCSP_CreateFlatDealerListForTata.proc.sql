CREATE PROCEDURE [DealerManagement].[uspDEALERS_JLRCSP_CreateFlatDealerListForTata]

AS

TRUNCATE TABLE DealerManagement.DEALERS_JLRCSP_FlatListForTata

-- GET ALL DEALERS

	CREATE TABLE #Dealers

		(
			Manufacturer NVARCHAR(200)
			, SuperNationalRegion NVARCHAR(200)
			, Market NVARCHAR(200)
			, SubNationalRegion NVARCHAR(200)
			, DealerGroup NVARCHAR(200)
			, DealerName NVARCHAR(200)
			, DealerCode NVARCHAR(50)
			, ManufacturerDealerCode NVARCHAR(50)
			, OutletPartyID INT
			, OutletFunction VARCHAR(20)
			, OutletFunctionID INT
			, FromDate SMALLDATETIME
			, ThroughDate SMALLDATETIME
			, TransferDealerName NVARCHAR(200)
			, TransferDealerCode NVARCHAR(50)
			, TransferPartyID INT
		)


	INSERT INTO #Dealers

		(
			Manufacturer
			, SuperNationalRegion
			, Market
			, SubNationalRegion
			, DealerGroup
			, DealerName
			, DealerCode
			, ManufacturerDealerCode
			, OutletPartyID
			, OutletFunction
			, OutletFunctionID
			, FromDate
			, ThroughDate
			, TransferDealerName
			, TransferDealerCode
			, TransferPartyID
		)	

			SELECT DISTINCT
				 Manufacturer
				,SuperNationalRegion
				,Market
				,SubNationalRegion
				,CombinedDealer AS DealerGroup
				,Outlet AS DealerName
				,OutletCode AS DealerCode
				,OutletsiteCode AS ManufacturerDealerCode
				,OutletPartyID
				,OutletFunction
				,OutletFunctionID
				,FromDate
				,ThroughDate
				,CASE
					WHEN TransferPartyID = OutletPartyID THEN NULL
					ELSE TransferDealer
				END AS TransferDealerName
				,CASE
					WHEN TransferPartyID = OutletPartyID THEN NULL
					ELSE TransferDealerCode
				END AS TransferDealerCode
				,CASE
					WHEN TransferPartyID = OutletPartyID THEN NULL
					ELSE TransferPartyID
				END AS TransferPartyID
			FROM [Sample].dbo.DW_JLRCSPDealers
			ORDER BY Manufacturer, SuperNationalRegion, Market, SubNationalRegion, OutletCode, Outlet


-- GET THE MATCHING CODES - Manufacturer

	CREATE TABLE #ManufacturerDealerCodes

		(
			ID INT IDENTITY(1, 1)
			, OutletPartyID INT
			, RoleTypeIDFrom INT
			, ManufacturerDealerCode NVARCHAR(50)
		)


	INSERT INTO #ManufacturerDealerCodes

		(
			OutletPartyID
			, RoleTypeIDFrom
			, ManufacturerDealerCode
		)

			SELECT DISTINCT 
				DN.PartyIDFrom AS OutletPartyID
				, DN.RoleTypeIDFrom
				--, dbo.udfGET_DealersCodesForMatching(DN.PartyIDFrom, DN.RoleTypeIDFrom, DN.RoleTypeIDTo) AS ManufacturerDealerCodes
				, DN.DealerCode
			FROM #Dealers D
			INNER JOIN Sample.Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID AND DN.RoleTypeIDFrom = D.OutletFunctionID
			WHERE DN.RoleTypeIDTo = 7
			AND ISNULL(DN.DealerCode, '') <> ''

-- GET THE MATCHING CODES - Standard

	CREATE TABLE #DealerCodes

		(
			ID INT IDENTITY(1,1)
			, OutletPartyID INT
			, RoleTypeIDFrom INT
			, DealerCodes NVARCHAR(50)
		)


	INSERT INTO #DealerCodes

		(
			OutletPartyID
			, RoleTypeIDFrom
			, DealerCodes
		)

			SELECT DISTINCT 
				DN.PartyIDFrom AS OutletPartyID
				, DN.RoleTypeIDFrom
				--, dbo.udfGET_DealersCodesForMatching(DN.PartyIDFrom, DN.RoleTypeIDFrom, DN.RoleTypeIDTo) AS DealerCodes
				, DN.DealerCode
			FROM #Dealers D
			INNER JOIN Sample.Party.DealerNetworks DN ON DN.PartyIDFrom = D.OutletPartyID AND DN.RoleTypeIDFrom = D.OutletFunctionID
			WHERE DN.RoleTypeIDTo = 19
			AND ISNULL(DN.DealerCode, '') <> ''


-- RECORD THE DATA

	INSERT INTO DealerManagement.DEALERS_JLRCSP_FlatListForTata

		(
			 Manufacturer
			, SuperNationalRegion
			, Market
			, SubNationalRegion
			, DealerGroup
			, DealerName
			, DealerCode
			, ManufacturerDealerCode
			, OutletPartyID
			, OutletFunction
			, OutletFunctionID
			, FromDate
			, ThroughDate
			, TransferDealerName
			, TransferDealerCode
			, TransferPartyID
--			, DealerCodes
--			, ManufacturerDealerCodes
			, Town
		)

			SELECT DISTINCT
				 D.Manufacturer
				, D.SuperNationalRegion
				, D.Market
				, D.SubNationalRegion
				, D.DealerGroup
				, D.DealerName
				, D.DealerCode
				, D.ManufacturerDealerCode
				, D.OutletPartyID
				, D.OutletFunction
				, D.OutletFunctionID
				, D.FromDate
				, D.ThroughDate
				, D.TransferDealerName
				, D.TransferDealerCode
				, D.TransferPartyID
--				, SDC.DealerCodes
--				, SMDC.ManufacturerDealerCodes
				, PA.Town
			FROM #Dealers D
--			LEFT JOIN #DealerCodes SDC ON SDC.OutletPartyID = D.OutletPartyID AND SDC.RoleTypeIDFrom = D.OutletFunctionID
--			LEFT JOIN #ManufacturerDealerCodes SMDC ON SMDC.OutletPartyID = D.OutletPartyID AND SMDC.RoleTypeIDFrom = D.OutletFunctionID
			LEFT JOIN Sample.ContactMechanism.PartyContactMechanisms PCM
				INNER JOIN [Sample].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PCM.ContactMechanismID
			ON PCM.PartyID = D.OutletPartyID

/* NOW ADD THE DEALER CODES */

	/* ADD DEALER CODES TO TEMP TABLE */

		SELECT 
			ROW_NUMBER() OVER (PARTITION BY OutletPartyID, RoleTypeIDFrom ORDER BY OutletPartyID, RoleTypeIDFrom) DealerCodeRecord
			,OutletPartyID
			, DealerCodes DealerCode
			, RoleTypeIDFrom
		INTO #DealerCodeRecords 	
		FROM #DealerCodes

	/* UPDATE EACH DEALER CODE COLUMN IF RELEVANT */

		UPDATE DL 
			SET DealerCode_1 = DC.DealerCode
		FROM #DealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 1


		UPDATE DL 
			SET DealerCode_2 = DC.DealerCode
		FROM #DealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 2
		
		
		UPDATE DL 
			SET DealerCode_3 = DC.DealerCode
		FROM #DealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 3
		
		
		UPDATE DL 
			SET DealerCode_4 = DC.DealerCode
		FROM #DealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 4
		
		
		
		UPDATE DL 
			SET DealerCode_5 = DC.DealerCode
		FROM #DealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 5
		
		
/* NOW ADD THE MANUFACTURER DEALER CODES */

	/* ADD MANAUFACTURER DEALER CODES TO TEMP TABLE */

		SELECT 
			ROW_NUMBER() OVER (PARTITION BY OutletPartyID, RoleTypeIDFrom ORDER BY OutletPartyID, RoleTypeIDFrom) DealerCodeRecord
			,OutletPartyID
			, ManufacturerDealerCode DealerCode
			, RoleTypeIDFrom
		INTO #ManufacturerDealerCodeRecords 	
		FROM #ManufacturerDealerCodes

	/* UPDATE EACH DEALER CODE COLUMN IF RELEVANT */

		UPDATE DL 
			SET ManufacturerDealerCode_1 = DC.DealerCode
		FROM #ManufacturerDealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 1


		UPDATE DL 
			SET ManufacturerDealerCode_2 = DC.DealerCode
		FROM #ManufacturerDealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 2
		
		
		UPDATE DL 
			SET ManufacturerDealerCode_3 = DC.DealerCode
		FROM #ManufacturerDealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 3
		
		
		UPDATE DL 
			SET ManufacturerDealerCode_4 = DC.DealerCode
		FROM #ManufacturerDealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 4
		
		
		
		UPDATE DL 
			SET ManufacturerDealerCode_5 = DC.DealerCode
		FROM #ManufacturerDealerCodeRecords DC
		INNER JOIN DealerManagement.DEALERS_JLRCSP_FlatListForTata DL ON DC.OutletPartyID = DL.OutletPartyID 
																	AND DC.RoleTypeIDFrom = DL.OutletFunctionID
		WHERE DC.DealerCodeRecord = 5		
		

/* WHAT WE GOT */

	--SELECT *
	--FROM DealerManagement.DEALERS_JLRCSP_FlatListForTata

/* DROP TEMPORARY TABLES */

	DROP TABLE #Dealers
	DROP TABLE #ManufacturerDealerCodes
	DROP TABLE #DealerCodes