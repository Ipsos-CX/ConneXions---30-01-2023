CREATE PROCEDURE [DealerManagement].[uspAddMissingDealersToEvents]

AS

/*
		Purpose:	Search for events that do not currently have a dealer assigned and see if we can now code
	
		Version		Date			Developer			Comment
LIVE	1.0			08/11/2013		Martin Riverol		Created
LIVE	1.1			26/11/2013		Martin Riverol		Do a second pass at recoding numeric dealercodes, ignoring the leading zero
LIVE	1.2			27/11/2013		Martin Riverol		Try to determine a Country of origin for multi market (warranty/cupid) file records so we can attempt to re-code them
LIVE	1.3			28/11/2013		Martin Riverol		Added CountryID to GDD dealer coding
LIVE	1.4			03/12/2013		Martin Riverol		BUG: #WarrantyParty table population causing duplicate audititems. Remove at the end.
LIVE	1.5			14/03/2014		Martin Riverol		Switch logic to derive respondent country from sample file prefix first, then postal address for event driven files. BUG# 10011
LIVE	1.6			23/04/2014		Martin Riverol		Proc over-running on UAT. Minor logic change to speed up execution.
LIVE	1.7			15/05/2014		Martin Riverol		Proc over-running on UAT and LIVE. Added index creation and working out if dealer code is numeric up front.
LIVE	1.8			06/08/2014		Martin Riverol		Work out if dealer code is numeric for warranty and event driven sample. Originally only doing cupid.
LIVE	1.9			28/11/2014		Chris Ross			BUG 11025 - Remove Global Sample Loader entries from countries vs load file lookup.  Stop dupes being created.
LIVE	1.10		26/01/2016		Chris Ross			BUG 12038 - Change hardcoded Dealer RoleTypes to use views.  Expanded final SalesDealer PartyID update to include PreOwned.
LIVE	1.11		05/02/2018		Chris Ledger		BUG 14108 - Speed Improvements
LIVE	1.12		03/10/2019		Chris Ledger		Exclude GfK_Sales_Export_ because multi market
LIVE	1.13		14/12/2020		Ben King			BUG 18045 Remove cast to BIGINT
LIVE	1.14		03/02/2021		Chris Ledger		TASK 249 - Remove matching on GDD Code 
LIVE	1.15		30/06/2021		Chris Ledger		TASK 522 - Remove further loaders from countries vs load file lookup to stop further duplicates being created
LIVE	1.16		16/08/2021      Ben King            TASK 583 - 18305 - Uncoded Luxembourg dealers
LIVE	1.17		31/08/2021		Chris Ledger		TASK 583 - Undo 1.16 (Luxembourg dealers are now coded differently)
LIVE	1.18		16/03/2022		Eddie Thomas		BUG 19463 - Remove further loaders from countries vs load file lookup to prevent Saudi Arabia events being coded as Taiwan

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


BEGIN TRY

	DECLARE @ActionDateFrom		DATETIME		
	DECLARE @ActionDateTo		DATETIME		

	SET @ActionDateFrom = GETDATE()-180
	SET @ActionDateTo = GETDATE()		


	CREATE TABLE #EventsWithNoDealer
	(
		AuditItemID INT,
		PartyID INT,
		RoleTypeID INT,
		EventID INT,
		DealerCode NVARCHAR(20),
		DealerCodeNumeric BIT,
		DealerCodeOriginatorPartyID INT,
		CountryID INT,
		AuditIDNew INT,
		AuditItemIDNew INT,			
		ManufacturerPartyID INT, 
		DealerPartyID INT,
		UseRowForUpdate BIT
	)
		
	CREATE TABLE #EventsWithDealerToCode
	(
		AuditItemID INT,
		PartyID INT,
		RoleTypeID INT,
		EventID INT,
		DealerCode NVARCHAR(20),
		DealerCodeOriginatorPartyID INT,
		CountryID INT,
		AuditIDNew INT,
		AuditItemIDNew INT,			
		ManufacturerPartyID INT, 
		DealerPartyID INT,
		UseRowForUpdate BIT
	)	

	/* IDENTIFY WHICH DEALERS HAVE NOT BEEN CODED */

	-- EVENT DRIVEN SAMPLE FILES
	;WITH CTE_SampleFileCountry AS 
	(
		SELECT DISTINCT 
			SampleFileNamePrefix,
			CountryID 
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
		WHERE LEN(SampleFileNamePrefix) > 1
			AND SampleFileNamePrefix NOT IN ('Combined_DDW_Service', 'Jaguar_Cupid_Sales', 'Combined_Roadside_Service')
			AND SampleFileNamePrefix NOT LIKE 'GSL_%'			-- V1.9
			AND SampleFileNamePrefix <> 'GfK_Sales_Export_'		-- V1.15
			AND SampleFileNamePrefix <> 'GfK_Sales_'			-- V1.18
			AND SampleFileNamePrefix <> 'Combined_CRC_LACRO'	-- V1.15
			AND SampleFileNamePrefix <> 'Combined_CRC_MENA'		-- V1.15
			AND SampleFileNamePrefix <> 'Combined_RA'			-- V1.15
			AND SampleFileNamePrefix <> 'Combined_RA_MENA'		-- V1.15
			AND SampleFileNamePrefix NOT LIKE 'CSD_%'			-- V1.15, V1.16, V1.17
			AND SampleFileNamePrefix NOT LIKE 'GfK_CQI%'		-- V1.15
			AND SampleFileNamePrefix NOT LIKE 'GfK_Service_%'	-- V1.15
			AND SampleFileNamePrefix <> 'GLCL_'					-- V1.15, V1.16, V1.17	
	)		
	INSERT INTO #EventsWithNoDealer
	(
		AuditItemID,
		PartyID,
		RoleTypeID,
		EventID,
		DealerCode,
		DealerCodeNumeric,
		DealerCodeOriginatorPartyID,
		CountryID
	)
	SELECT DISTINCT
		AEPR.AuditItemID,
		AEPR.PartyID,
		AEPR.RoleTypeID,
		AEPR.EventID,
		AEPR.DealerCode,
		dbo.udfIsNumeric(AEPR.DealerCode),
		AEPR.DealerCodeOriginatorPartyID,
		COALESCE(SFC.CountryID, APA.CountryID) AS CountryID
	FROM [$(AuditDB)].Audit.EventPartyRoles AEPR
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AEPR.AuditItemID = AI.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
										AND F.ActionDate BETWEEN @ActionDateFrom AND @ActionDateTo		-- V1.11
		LEFT JOIN [$(AuditDB)].Audit.PostalAddresses APA ON AI.AuditItemID = APA.AuditItemID
		LEFT JOIN CTE_SampleFileCountry SFC ON F.FileName LIKE SFC.SampleFileNamePrefix + '%'
	WHERE AEPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)								-- V1.10
		AND AEPR.PartyID = 0
		AND NOT EXISTS (	SELECT 1 
							FROM Event.EventPartyRoles EPR 
							WHERE EPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)		-- V1.10
								AND EPR.EventID = AEPR.EventID)

	
	-- CUPID SAMPLE FILES
	INSERT INTO #EventsWithNoDealer
	(
		AuditItemID,
		PartyID,
		RoleTypeID,
		EventID,
		DealerCode,
		DealerCodeNumeric,
		DealerCodeOriginatorPartyID,
		CountryID
	)
	SELECT DISTINCT
		AEPR.AuditItemID,
		AEPR.PartyID,
		AEPR.RoleTypeID,
		AEPR.EventID,
		AEPR.DealerCode,
		dbo.udfIsNumeric(AEPR.DealerCode),
		AEPR.DealerCodeOriginatorPartyID,
		APA.CountryID
	FROM [$(AuditDB)].Audit.EventPartyRoles AEPR
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AEPR.AuditItemID = AI.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
							AND F.ActionDate BETWEEN @ActionDateFrom AND @ActionDateTo				-- V1.11
		LEFT JOIN [$(AuditDB)].Audit.PostalAddresses APA ON AI.AuditItemID = APA.AuditItemID
	WHERE AEPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)							-- V1.10
		AND F.FileName LIKE 'Jaguar_Cupid_Sales%'
		AND AEPR.PartyID = 0
		AND NOT EXISTS (	SELECT 1 
							FROM Event.EventPartyRoles EPR 
							WHERE EPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)  -- V1.10
								AND EPR.EventID = AEPR.EventID)


	-- WARRANTY FILES
	CREATE TABLE #WarrantyParties
	(
		AuditItemID INT,
		EventID INT,
		RespondentPartyID INT
	)
		
	INSERT INTO #WarrantyParties
	(
		AuditItemID,
		EventID,
		RespondentPartyID
	)
	SELECT AI.AuditItemID, 
		AVPRE.EventID, 
		PartyID AS RespondentPartyID
	FROM [$(AuditDB)].dbo.Files F
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON F.AuditID = AI.AuditID
		INNER JOIN [$(AuditDB)].Audit.VehiclePartyRoleEvents AVPRE ON AI.AuditItemID = AVPRE.AuditItemID
	WHERE F.FileName LIKE 'Combined_DDW_Service%'
		AND F.ActionDate BETWEEN @ActionDateFrom AND @ActionDateTo				-- V1.11


	/* CREATE A COVERING INDEX */
	CREATE CLUSTERED INDEX IDX_WarrantyParties 
		ON #WarrantyParties(AuditItemID, EventID, RespondentPartyID)

	INSERT INTO #EventsWithNoDealer
	(
		AuditItemID,
		PartyID,
		RoleTypeID,
		EventID,
		DealerCode,
		DealerCodeNumeric,
		DealerCodeOriginatorPartyID,
		CountryID
	)
	SELECT DISTINCT
		AEPR.AuditItemID,
		AEPR.PartyID,
		AEPR.RoleTypeID,
		AEPR.EventID,
		AEPR.DealerCode,
		dbo.udfIsNumeric(AEPR.DealerCode),
		AEPR.DealerCodeOriginatorPartyID,
		A.CountryID
	FROM [$(AuditDB)].Audit.EventPartyRoles AEPR
		INNER JOIN #WarrantyParties WP ON AEPR.EventID = WP.EventID AND AEPR.AuditItemID = WP.AuditItemID
		INNER JOIN Meta.PartyBestPostalAddresses PA ON WP.RespondentPartyID = PA.PartyID
		INNER JOIN ContactMechanism.PostalAddresses A ON PA.ContactMechanismID = A.ContactMechanismID
	WHERE AEPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)				-- V1.10
		AND AEPR.PartyID = 0
		AND NOT EXISTS (SELECT 1 FROM Event.EventPartyRoles EPR WHERE EPR.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwDealerRoleTypes)  -- V1.10
																			AND EPR.EventID = AEPR.EventID)

	/* DROP WARRANTY TABLE. NO LONGER REQUIRED */
	DROP TABLE #WarrantyParties
	

	/* ADD MANUFACTURER OF THE VEHICLE FOR THE EVENT */
	CREATE TABLE #ManufacturerEvents 
	(
		EventID INT NOT NULL,
		VehicleID INT NOT NULL,
		ManufacturerPartyID INT NOT NULL
	)


	INSERT INTO #ManufacturerEvents 
	(
		EventID,
		VehicleID,
		ManufacturerPartyID
	)
	SELECT DISTINCT
		VPRE.EventID,
		V.VehicleID,
		M.ManufacturerPartyID
	FROM Vehicle.VehiclePartyRoleEvents VPRE
		INNER JOIN Vehicle.Vehicles V ON VPRE.VehicleID = V.VehicleID
		INNER JOIN Vehicle.Models M ON V.ModelID = M.ModelID

					
	UPDATE ND
	SET ManufacturerPartyID = ME.ManufacturerPartyID 
	FROM #EventsWithNoDealer ND
		INNER JOIN #ManufacturerEvents ME ON ND.EventID = ME.EventID

		
	/* ADD SOME INDEXING */	
	CREATE NONCLUSTERED INDEX IDX_EventsWithNoDealer 
		ON #EventsWithNoDealer(DealerCode) 
		INCLUDE (RoleTypeID, DealerPartyID, CountryID, DealerCodeNumeric)
	

	/* CODE DEALERS IN THE SAME WAY WE WOULD DO DURING A LOAD */		

	--- FIRST PASS - MATCH WHERE COUNTRY MATCHES -----------------------			
			
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON LTRIM(RTRIM(V.DealerCode)) = D.DealerCode
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.DealerCodeOriginatorPartyID
		AND D.CountryID = V.CountryID
		AND V.DealerPartyID IS NULL

	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON LTRIM(RTRIM(V.DealerCode)) = D.DealerCode
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.ManufacturerPartyID
		AND D.CountryID = V.CountryID
		AND ISNULL(V.DealerPartyID, 0) = 0

			
	--- SECOND PASS - WHERE NOT MATCHED, THEN LINK WHERE DEALER COUNTRY IS NOT SET
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON LTRIM(RTRIM(V.DealerCode)) = D.DealerCode
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.DealerCodeOriginatorPartyID
		AND D.CountryID IS NULL
		AND ISNULL(V.DealerPartyID, 0) = 0
			
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON LTRIM(RTRIM(V.DealerCode)) = D.DealerCode
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.ManufacturerPartyID
		AND D.CountryID IS NULL
		AND ISNULL(V.DealerPartyID, 0) = 0


	-- IN ADDITION, TRY THE GDD CODE FROM THE DEALER HIERARCHY TABLE -- V1.14 REMOVED
	/*
	UPDATE V
	SET DealerPartyID = D.OutletPartyID
	FROM dbo.DW_JLRCSPDealers D 
		INNER JOIN DealerManagement.vwDealers VW ON D.OutletPartyID = VW.DealerID
											AND D.OutletFunctionID = VW.RoleTypeIDFrom											
		INNER JOIN #EventsWithNoDealer V ON LTRIM(RTRIM(V.DealerCode)) = D.OutletCode_GDD
										AND V.RoleTypeID = D.OutletFunctionID
										AND V.CountryID = VW.CountryID											
	WHERE D.ManufacturerPartyID = V.ManufacturerPartyID
		AND D.OutletPartyID = D.TransferPartyID
		AND ISNULL(V.DealerPartyID, 0) = 0
	*/

	
	-- IN ADDITION LETS STRIP OUT THE LEADING ZERO AND COMPARE ANY NUMERIC DEALER CODES
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON V.DealerCode = D.DealerCode			-- V1.13
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.DealerCodeOriginatorPartyID
		AND D.CountryID = V.CountryID
		AND V.DealerPartyID IS NULL
		AND dbo.udfIsNumeric(D.DealerCode) = 1
		AND V.DealerCodeNumeric = 1


	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON V.DealerCode = D.DealerCode			-- V1.13
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.ManufacturerPartyID
		AND D.CountryID = V.CountryID
		AND ISNULL(V.DealerPartyID, 0) = 0
		AND dbo.udfIsNumeric(D.DealerCode) = 1
		AND V.DealerCodeNumeric = 1
			
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON V.DealerCode = D.DealerCode			-- V1.13
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.DealerCodeOriginatorPartyID
		AND D.CountryID IS NULL
		AND ISNULL(V.DealerPartyID, 0) = 0
		AND dbo.udfIsNumeric(D.DealerCode) = 1
		AND V.DealerCodeNumeric = 1
			
	UPDATE V
	SET V.DealerPartyID = D.DealerID
	FROM DealerManagement.vwDealers D 
		INNER JOIN #EventsWithNoDealer V ON V.DealerCode = D.DealerCode -- V1.13
										AND V.RoleTypeID = D.RoleTypeIDFrom
	WHERE D.PartyIDTo = V.ManufacturerPartyID
		AND D.CountryID IS NULL
		AND ISNULL(V.DealerPartyID, 0) = 0
		AND dbo.udfIsNumeric(D.DealerCode) = 1
		AND V.DealerCodeNumeric = 1

	
	/* THERE ARE DUPLICATES WHEN WE GET THE SAME EVENTID IN MORE THAN ONCE THEREFORE ONLY MARK ONE UNIQUE EVENT TO USE FOR THE UPDATE */

	;WITH CTE_RowsToUpdate AS
	(
		SELECT RoleTypeID, 
			EventID, 
			MAX(AuditItemID) AS AuditItemID
		FROM #EventsWithNoDealer
		WHERE ISNULL(DealerPartyID, 0) > 0
		GROUP BY RoleTypeID, 
			EventID
	)
	UPDATE D
	SET UseRowForUpdate = 1
	FROM #EventsWithNoDealer D
		INNER JOIN CTE_RowsToUpdate ND ON D.RoleTypeID = ND.RoleTypeID
									AND D.EventID = ND.EventID
									AND D.AuditItemID = ND.AuditItemID
		
	-- REMOVE SUPERFLOUS ROWS								
	DELETE FROM #EventsWithNoDealer
	WHERE UseRowForUpdate IS NULL
		
	-- NOT SURE WHERE THEE ARE COMING FROM BUT REMOVE THEM 
	DELETE FROM #EventsWithNoDealer
	WHERE DealerPartyID IS NULL
		

	-- REMOVE DUPLICATE ROWS CAUSED BY #WARRANTYPARTIES
	INSERT INTO #EventsWithDealerToCode
	(
		AuditItemID,
		PartyID,
		RoleTypeID,
		EventID,
		DealerCode,
		DealerCodeOriginatorPartyID,
		CountryID,
		AuditIDNew,
		AuditItemIDNew,
		ManufacturerPartyID,
		DealerPartyID,
		UseRowForUpdate
	)
	SELECT AuditItemID, 
		PartyID, 
		RoleTypeID, 
		EventID, 
		DealerCode, 
		DealerCodeOriginatorPartyID, 
		MAX(CountryID) AS CountryID, 
		AuditIDNew, 
		AuditItemIDNew, 
		ManufacturerPartyID, 
		DealerPartyID, 
		UseRowForUpdate
	FROM #EventsWithNoDealer 
	GROUP BY AuditItemID, 
		PartyID, 
		RoleTypeID, 
		EventID, 
		DealerCode, 
		DealerCodeOriginatorPartyID, 
		AuditIDNew, 
		AuditItemIDNew, 
		ManufacturerPartyID, 
		DealerPartyID, 
		UseRowForUpdate
		
	-- ADD CONSTRAINT TO ENSURE UNIQUENESS OF EVENT
	/* HAD TO TAKE THIS OUT BECAUSE OF LANDROVER_BELGIUM_SALES HAVING TWO COUNTRIES */
	--	ALTER TABLE #EventsWithNoDealer
	--	ADD CONSTRAINT UC_EventID UNIQUE (EventID)
		
	
	/* CREATE A NEW AUDIT TRAIL FOR THE DATA OF FILETYPE 12 - INTERNAL UPDATE */
	DECLARE @AuditID INT
	DECLARE @maxAuditItemID INT
	DECLARE @RecsToUpdate INT
		
	SELECT @RecsToUpdate = COUNT(*) 
	FROM #EventsWithDealerToCode D
		INNER JOIN Party.PartyRoles PR ON D.DealerPartyID = PR.PartyID
										AND D.RoleTypeID = PR.RoleTypeID
		
	SELECT @AuditID = MAX(AuditID) + 1 
	FROM [$(AuditDB)].dbo.Audit
				
	INSERT INTO [$(AuditDB)].dbo.Audit 
	(
		AuditID
	)
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
		'IU_AssignDealer_' + CONVERT(VARCHAR(100), GETDATE(), 121) AS FileName,
		@RecsToUpdate AS FileRowCount,
		12 AS FileTypeID
				
			
	UPDATE EWND
	SET AuditIDNew = @AuditID, 
		AuditItemIDNew = X.AuditItemIDNew 
	FROM #EventsWithDealerToCode EWND
		INNER JOIN (	SELECT AuditItemID, 
							ROW_NUMBER() OVER (ORDER BY DealerPartyID) + (SELECT MAX(AuditItemID) + 1 FROM [Sample_Audit].dbo.AuditItems) AS AuditItemIDNew 				
						FROM #EventsWithDealerToCode) X ON EWND.AuditItemID = X.AuditItemID
			

	INSERT INTO [$(AuditDB)].dbo.AuditItems
	(
		AuditID,
		AuditItemID
	)
	SELECT 
		AuditIDNew,
		AuditItemIDNew
	FROM #EventsWithDealerToCode
			
		
	INSERT INTO	Event.vwDA_EventPartyRoles
	(
		AuditItemID,
		DealerCode,
		DealerCodeOriginatorPartyID,
		EventID,
		RoleTypeID,
		PartyID
	)
	SELECT 
		AuditItemIDNew,
		DealerCode,
		COALESCE(DealerCodeOriginatorPartyID, ManufacturerPartyID),
		EventID,
		D.RoleTypeID,
		DealerPartyID
	FROM #EventsWithDealerToCode D
		INNER JOIN Party.PartyRoles PR ON D.DealerPartyID = PR.PartyID
										AND D.RoleTypeID = PR.RoleTypeID
			
	
/* UPDATE SAMPLE LOGGING TABLE */
	
	UPDATE SQSL
	SET UncodedDealer = 0, 
		ServiceDealerID = D.DealerPartyID
	FROM #EventsWithDealerToCode D
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQSL ON D.EventID = SQSL.MatchedODSEventID
	WHERE D.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwServiceDealerRoleTypes)			-- V1.10
		
	UPDATE SQSL
	SET UncodedDealer = 0, 
		SalesDealerID = D.DealerPartyID
	FROM #EventsWithDealerToCode D
		INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SQSL ON D.EventID = SQSL.MatchedODSEventID
	WHERE D.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwSalesDealerRoleTypes)			-- V1.10
		OR D.RoleTypeID IN (SELECT RoleTypeID FROM dbo.vwPreOwnedDealerRoleTypes)		-- V1.10		
				
			
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

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)

END CATCH