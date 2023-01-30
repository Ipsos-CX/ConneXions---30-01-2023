CREATE PROCEDURE Stage.uspTurkeyResponses_Matching

AS

/*
		Purpose:	SP to match CountryID, LanguageID, ManufacturerPartyID, EventTypeID, OutletFunctionID, OutletPartyID, VehicleID, ModelID & EventID
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-12		Chris Ledger		Created
LIVE	1.1			2021-11-06		Chris Ledger		TASK 598 - change matching of CaseID from e_bp_uniquerecordid_txt to e_jlr_case_id_text
LIVE	1.2			2022-01-11		Chris Ledger		Task 747 - Use temporary table to fix bug in MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO STRIPPING OUT LEADING ZEROS)
LIVE	1.3			2022-04-01		Chris Ledger		Task 719 - Use new model matching
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
	UPDATE TR
	SET TR.CountryID = C.CountryID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON TR.e_jlr_country_id_enum = C.CountryID


	-- SET LANGUAGEID
	UPDATE TR
	SET TR.LanguageID = L.LanguageID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].dbo.Languages L ON TR.e_jlr_language_id_enum = L.LanguageID


	-- SET MANUFACTURERPARTYID
	UPDATE TR
	SET TR.ManufacturerPartyID = B.ManufacturerPartyID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].dbo.Brands B ON TR.e_jlr_manufacturer_id_enum = B.ManufacturerPartyID


	-- SET EVENTTYPEID & OUTLETFUNCTIONID
	UPDATE TR
	SET TR.EventTypeID = ET.EventTypeID,
		TR.OutletFunctionID = ET.RelatedOutletFunctionID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON TR.e_jlr_event_type_id_enum = ET.EventTypeID 


	-- ADD TRAILING *'S TO MAKE e_jlr_vehicle_identification_number_text = 17 CHARACTERS
	UPDATE TR
	SET TR.e_jlr_vehicle_identification_number_text = SUBSTRING(TR.e_jlr_vehicle_identification_number_text + '*****************',1,17)
	FROM Stage.TurkeyResponses TR


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
		FROM CTE_VehicleMatch VM
			INNER JOIN [$(SampleDB)].Vehicle.vwVehicles V ON VM.VehicleID = V.VehicleID
	)
	UPDATE TR
	SET TR.VehicleID = VM.VehicleID,
		TR.ModelID = VM.ModelID,
		TR.ModelVariantID = VM.ModelVariantID		--V1.3
	FROM Stage.TurkeyResponses TR
		INNER JOIN CTE_Vehicles VM ON TR.e_jlr_vehicle_identification_number_text = VM.VehicleChecksum		-- V1.1
	WHERE ISNULL(TR.VehicleID, 0) = 0


	-- MATCH VEHICLEID'S OF CHILDREN TO PARENTS
	UPDATE TR 
	SET TR.VehicleID = API1.VehicleID
	FROM Stage.TurkeyResponses TR
		INNER JOIN Stage.TurkeyResponses API1 ON TR.VehicleParentAuditItemID = API1.AuditItemID
	WHERE ISNULL(TR.VehicleID, 0) = 0


	-- MATCH MODELID ON VIN
	UPDATE TR
	SET TR.ModelID = MVM.ModelID,
		TR.ModelVariantID = MVM.ModelVariantID		-- V1.3
	FROM Stage.TurkeyResponses TR
		INNER JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings VMS ON TR.e_jlr_vehicle_identification_number_text LIKE CASE	WHEN SUBSTRING(TR.e_jlr_vehicle_identification_number_text,12,1) = '*' THEN COALESCE(VMS.ElevenCharacterVehicleMatchingString,VMS.VehicleMatchingString)
																																ELSE VMS.VehicleMatchingString END
		INNER JOIN [$(SampleDB)].Vehicle.ModelVariantMatching MVM ON MVM.VehicleMatchingStringID = VMS.VehicleMatchingStringID		-- V1.3
	WHERE ISNULL(TR.ModelID, 0) = 0
		AND VMS.VehicleMatchingStringTypeID = 1


	-- MATCH OUTLETPARTYID (USING E_JLR_DEALER_CODE_AUTO)
	UPDATE TR
	SET TR.OutletPartyID = F.OutletPartyID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON TR.EventTypeID = ET.EventTypeID
		LEFT JOIN [$(SampleDB)].dbo.Franchises F ON F.OutletFunctionID = TR.OutletFunctionID
												AND F.ManufacturerPartyID = TR.ManufacturerPartyID
												AND F.CountryID = TR.CountryID
												AND F.FranchiseCICode = TR.e_jlr_dealer_code_auto


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

	UPDATE TR
	SET TR.OutletPartyID = F.OutletPartyID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON TR.EventTypeID = ET.EventTypeID
		LEFT JOIN #Franchises F ON F.OutletFunctionID = TR.OutletFunctionID								-- V1.2
												AND F.ManufacturerPartyID = TR.ManufacturerPartyID
												AND F.CountryID = TR.CountryID
	WHERE [$(SampleDB)].dbo.udfIsNumeric(TR.e_jlr_dealer_code_auto) = 1
		AND TR.OutletPartyID IS NULL
		AND LEN(TR.e_jlr_dealer_code_auto) > 0															
		AND F.FranchiseCICode = CAST(TR.e_jlr_dealer_code_auto AS BIGINT)								-- V1.2	

	
	-- MATCH OUTLETPARTYID (USING E_JLR_GLOBAL_DEALER_CODE_AUTO)
	UPDATE TR
	SET TR.OutletPartyID = F.OutletPartyID
	FROM Stage.TurkeyResponses TR
		LEFT JOIN [$(SampleDB)].Event.EventTypes ET ON TR.EventTypeID = ET.EventTypeID
		LEFT JOIN [$(SampleDB)].dbo.Franchises F ON F.OutletFunctionID = TR.OutletFunctionID
												AND F.ManufacturerPartyID = TR.ManufacturerPartyID
												AND F.CountryID = TR.CountryID
												AND F.[10CharacterCode] = TR.e_jlr_global_dealer_code_auto
	WHERE TR.OutletPartyID IS NULL			
	
	
	-- MATCH EVENTID & CASEID
	UPDATE TR
	SET TR.EventID = AAPI.EventID,
		TR.CaseID = AAPI.CaseID
	FROM Stage.TurkeyResponses TR
		INNER JOIN [$(AuditDB)].Audit.TurkeyResponses AAPI ON ISNULL(TR.e_jlr_event_date, GETDATE()) = ISNULL(AAPI.e_jlr_event_date, GETDATE())
								AND TR.EventTypeID = AAPI.EventTypeID
								AND TR.OutletPartyID = AAPI.OutletPartyID
								AND TR.VehicleID = AAPI.VehicleID
								AND TR.e_jlr_case_id_text = AAPI.e_jlr_case_id_text			-- V1.1

	
	-- V1.4 MATCH DEALER BRAND TO MODEL (SET MANUFACTURERPARTYID TO NULL)
	UPDATE TR
	SET TR.ManufacturerPartyID = NULL
	FROM Stage.TurkeyResponses TR
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON TR.ModelID = M.ModelID
	WHERE ISNULL(TR.ManufacturerPartyID,0) <> ISNULL(M.ManufacturerPartyID,0)


	-- SET VALIDATION
	UPDATE TR
	SET TR.ValidatedData = 1
	FROM Stage.TurkeyResponses TR
	WHERE ISNULL(TR.CountryID,0) > 0
		AND ISNULL(TR.EventTypeID,0) > 0
		AND ISNULL(TR.ManufacturerPartyID,0) > 0
		AND ISNULL(TR.ModelID,0) > 0
		AND ISNULL(TR.OutletPartyID,0) > 0				

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