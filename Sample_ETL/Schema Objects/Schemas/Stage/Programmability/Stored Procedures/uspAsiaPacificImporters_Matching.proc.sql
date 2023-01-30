CREATE PROCEDURE Stage.uspAsiaPacificImporters_Matching

AS

/*
		Purpose:	SP to match CountryID, LanguageID, ManufacturerPartyID, EventTypeID, OutletFunctionID, OutletPartyID, VehicleID, ModelID & EventID
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-12		Chris Ledger		Created
LIVE	1.1			2021-12-21		Chris Ledger		Task 598 - Fix bug in MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO STRIPPING OUT LEADING ZEROS)
LIVE	1.2			2022-01-11		Chris Ledger		Task 747 - Use temporary table to fix bug in MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO STRIPPING OUT LEADING ZEROS)
LIVE	1.3			2022-04-01		Chris Ledger		Task 729 - Use new model matching
LIVE	1.4			2022-04-08		Chris Ledger		Task 850 - match model brand with dealer brand
*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- SET COUNTRYID
	UPDATE API
	SET API.CountryID = CASE	WHEN C.CountryShortName = 'Macao' THEN (SELECT C.CountryID FROM [$(SampleDB)].ContactMechanism.Countries C WHERE C.CountryShortName = 'Hong Kong')
								ELSE C.CountryID END
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON API.e_jlr_country_id_enum = C.ISOAlpha2


	-- SET LANGUAGEID
	UPDATE API
	SET API.LanguageID = CASE	WHEN C.Country = 'Taiwan Province of China' AND L.Language = 'Chinese' THEN (SELECT L.LanguageID FROM [$(SampleDB)].dbo.Languages L WHERE L.Language = 'Taiwanese Chinese (Taiwan)')
								ELSE L.LanguageID END
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON API.e_jlr_country_id_enum = C.ISOAlpha2
		LEFT JOIN [$(SampleDB)].dbo.Languages L ON API.e_jlr_language_id_enum = COALESCE(L.APIOLanguage, L.Language)


	-- SET MANUFACTURERPARTYID
	UPDATE API
	SET API.ManufacturerPartyID = B.ManufacturerPartyID
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].dbo.Brands B ON API.e_jlr_manufacturer_enum = B.ManufacturerPartyID


	-- SET EVENTTYPEID & OUTLETFUNCTIONID
	UPDATE API
	SET API.EventTypeID = ET.EventTypeID,
		API.OutletFunctionID = ET.RelatedOutletFunctionID
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON API.e_jlr_event_type_id_enum = ET.EventTypeID 


	-- MATCH VEHICLEID
	;WITH CTE_VehicleMatch (VehicleChecksum, ModelID, VehicleID) AS
	(
		SELECT V.VehicleChecksum, 
			V.ModelID, 
			MAX(V.VehicleID) AS VehicleID
		FROM [$(SampleDB)].Vehicle.vwVehicles V
		GROUP BY V.VehicleChecksum, 
			V.ModelID
	), CTE_Vehicles (VehicleChecksum, ModelID, ModelVariantID, ModelYear, VehicleID) AS		-- V1.3
	(
		SELECT V.VehicleChecksum,
			V.ModelID,
			V.ModelVariantID,
			V.ModelYear,
			V.VehicleID
		FROM CTE_VehicleMatch VM		-- V1.3
			INNER JOIN [$(SampleDB)].Vehicle.vwVehicles V ON VM.VehicleID = V.VehicleID
	)	
	UPDATE API
	SET API.VehicleID = VM.VehicleID,
		API.ModelID = VM.ModelID,
		API.ModelVariantID = VM.ModelVariantID		--V1.3
	FROM Stage.AsiaPacificImporters API
		INNER JOIN CTE_Vehicles VM ON API.e_jlr_vehicle_identification_number_text = VM.VehicleChecksum		-- V1.3
	WHERE LEN(ISNULL(API.e_jlr_vehicle_identification_number_text,'')) = 17
		AND ISNULL(API.VehicleID, 0) = 0


	-- MATCH VEHICLEID'S OF CHILDREN TO PARENTS
	UPDATE API 
	SET API.VehicleID = API1.VehicleID
	FROM Stage.AsiaPacificImporters API
		INNER JOIN Stage.AsiaPacificImporters API1 ON API.VehicleParentAuditItemID = API1.AuditItemID
	WHERE LEN(ISNULL(API.e_jlr_vehicle_identification_number_text,'')) = 17
		AND ISNULL(API.VehicleID, 0) = 0


	-- MATCH MODELID ON VIN
	UPDATE API
	SET API.ModelID = MVM.ModelID,
		API.ModelVariantID = MVM.ModelVariantID		-- V1.3
	FROM Stage.AsiaPacificImporters API
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON API.e_jlr_vehicle_identification_number_text LIKE VMS.VehicleMatchingString
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariantMatching MVM ON MVM.VehicleMatchingStringID = VMS.VehicleMatchingStringID		-- V1.3
	WHERE ISNULL(API.ModelID, 0) = 0
		AND VMS.VehicleMatchingStringTypeID = 1
		AND LEN(REPLACE(API.e_jlr_vehicle_identification_number_text, ' ', '')) = 17


	-- MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO)
	UPDATE API
	SET API.OutletPartyID = F.OutletPartyID
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON API.EventTypeID = ET.EventTypeID
		LEFT JOIN [$(SampleDB)].dbo.Franchises F ON F.OutletFunctionID = API.OutletFunctionID
												AND F.ManufacturerPartyID = API.ManufacturerPartyID
												AND F.CountryID = API.CountryID
												AND F.FranchiseCICode = API.e_jlr_dealer_code_auto


	-- MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO STRIPPING OUT LEADING ZEROS)
	DROP TABLE IF EXISTS #Franchises

	SELECT F.OutletPartyID,
		F.OutletFunctionID,
		CAST(F.FranchiseCICode AS BIGINT) AS FranchiseCICode,
		F.ManufacturerPartyID,
		F.CountryID
	INTO #Franchises
	FROM [$(SampleDB)].dbo.Franchises F
	WHERE [$(SampleDB)].dbo.udfIsNumeric(F.FranchiseCICode) = 1

	UPDATE API
	SET API.OutletPartyID = F.OutletPartyID
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON API.EventTypeID = ET.EventTypeID
		LEFT JOIN #Franchises F ON F.OutletFunctionID = API.OutletFunctionID							-- V1.2
												AND F.ManufacturerPartyID = API.ManufacturerPartyID
												AND F.CountryID = API.CountryID
	WHERE [$(SampleDB)].dbo.udfIsNumeric(API.e_jlr_dealer_code_auto) = 1
		AND API.OutletPartyID IS NULL
		AND LEN(API.e_jlr_dealer_code_auto) > 0															-- V1.1
		AND F.FranchiseCICode = CAST(API.e_jlr_dealer_code_auto AS BIGINT)								-- V1.2	


	-- MATCH OUTLETPARTYID (USING E_JLR_GLOBAL_DEALER_CODE_AUTO)
	UPDATE API
	SET API.OutletPartyID = F.OutletPartyID
	FROM Stage.AsiaPacificImporters API
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON API.EventTypeID = ET.EventTypeID
		LEFT JOIN [$(SampleDB)].dbo.Franchises F ON F.OutletFunctionID = API.OutletFunctionID
												AND F.ManufacturerPartyID = API.ManufacturerPartyID
												AND F.CountryID = API.CountryID
												AND F.[10CharacterCode] = API.e_jlr_global_dealer_code_auto
	WHERE API.OutletPartyID IS NULL											

	
	-- MATCH EVENTID & CASEID
	UPDATE API
	SET API.EventID = AAPI.EventID,
		API.CaseID = AAPI.CaseID
	FROM Stage.AsiaPacificImporters API
		INNER JOIN [$(AuditDB)].Audit.AsiaPacificImporters AAPI ON ISNULL(API.e_jlr_event_date, GETDATE()) = ISNULL(AAPI.e_jlr_event_date, GETDATE())
								AND API.EventTypeID = AAPI.EventTypeID
								AND API.OutletPartyID = AAPI.OutletPartyID
								AND API.VehicleID = AAPI.VehicleID
								AND API.e_bp_uniquerecordid_txt = AAPI.e_bp_uniquerecordid_txt


	-- V1.4 MATCH DEALER BRAND TO MODEL (SET MANUFACTURERPARTYID TO NULL)
	UPDATE API
	SET API.ManufacturerPartyID = NULL
	FROM Stage.AsiaPacificImporters API
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON API.ModelID = M.ModelID
	WHERE ISNULL(API.ManufacturerPartyID,0) <> ISNULL(M.ManufacturerPartyID,0)
	

	-- SET VALIDATION
	UPDATE API
	SET API.ValidatedData = 1
	FROM Stage.AsiaPacificImporters API
	WHERE ISNULL(API.CountryID,0) > 0
		AND ISNULL(API.EventTypeID,0) > 0
		AND ISNULL(API.ManufacturerPartyID,0) > 0
		AND ISNULL(API.ModelID,0) > 0
		AND ISNULL(API.OutletPartyID,0) > 0				

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