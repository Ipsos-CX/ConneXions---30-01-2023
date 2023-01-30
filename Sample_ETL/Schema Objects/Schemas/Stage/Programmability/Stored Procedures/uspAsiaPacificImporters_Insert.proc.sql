CREATE PROCEDURE Stage.uspAsiaPacificImporters_Insert

AS

/* 
		Purpose:	Insert new records into [$(SampleDB)].SelectionOutput.AsiaPacificImporters table
	
		Version		Date			Developer			Comment										
LIVE	1.0			2017-04-21		Chris Ledger		Created
LIVE	1.1			2022-04-19		Chris Ledger		Task 859 - blank out electric vehicle questions if EngineDescription not BEV or PHEV
LIVE	1.2			2022-06-13		Chris Ledger		Task 729 - remove adding of Jaguar to e_jlr_model_description_text
LIVE	1.3			2022-09-12		Eddie Thomas		Task 1017 - Populate new field e_jlr_sub_brand_text

*/

SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		;WITH CTE_AuditItemIDs AS
		(
			SELECT API.ParentAuditItemID AS AuditItemID
			FROM Stage.AsiaPacificImporters API
			GROUP BY API.ParentAuditItemID
		), CTE_ModelCodes AS
		(
			SELECT B.Brand,
				M.ModelID,
				M.ModelDescription,
				RM.RequirementID AS [ModelCode],
				RM.Requirement AS [Model Requirement],
				COUNT(*) AS COUNT
			FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM
				INNER JOIN [$(SampleDB)].Requirement.Requirements R ON SM.QuestionnaireRequirementID = R.RequirementID
				INNER JOIN [$(SampleDB)].Requirement.QuestionnaireModelRequirements QMR ON SM.QuestionnaireRequirementID = QMR.RequirementIDPartOf
				INNER JOIN [$(SampleDB)].Requirement.ModelRequirements MR ON MR.RequirementID = QMR.RequirementIDMadeUpOf
				INNER JOIN [$(SampleDB)].Requirement.Requirements RM ON MR.RequirementID = RM.RequirementID
				INNER JOIN [$(SampleDB)].Vehicle.Models M ON MR.ModelID = M.ModelID
				INNER JOIN [$(SampleDB)].dbo.Brands B ON M.ManufacturerPartyID = B.ManufacturerPartyID
			WHERE SM.SampleLoadActive = 1
				AND SM.Market = 'United Kingdom'
				AND SM.Questionnaire = 'Sales'
			GROUP BY B.Brand,
				M.ModelID,
				M.ModelDescription,
				RM.RequirementID,
				RM.Requirement
		)
		INSERT INTO [$(SampleDB)].SelectionOutput.AsiaPacificImporters
		SELECT API.AuditItemID,
			API.EventID,
			API.CaseID,
			API.EventTypeID,
			API.CountryID,
			API.LanguageID,
			API.ManufacturerPartyID,
			API.VehicleID,
			API.ModelID,
			API.OutletPartyID,
			API.OutletFunctionID,
			API.ValidatedData,
			NULL AS OutputToMedalliaDate,
			NULL AS OutputAuditID,
			API.CaseID AS e_jlr_case_id_text,
			e_bp_uniquerecordid_txt,
			API.EventTypeID AS e_jlr_survey_type_id_enum,
			MC.ModelCode AS e_jlr_model_code_auto,
			M.OutputFileModelDescription AS e_jlr_model_description_text,		-- V1.2
			V.BuildYear AS e_jlr_model_year_auto,
			M.ManufacturerPartyID AS e_jlr_manufacturer_id_enum,
			B.Brand AS e_jlr_manufacturer_enum,
			API.e_jlr_car_registration_text,
			API.e_jlr_vehicle_identification_number_text,
			V.ModelVariantID AS e_jlr_model_variant_code_auto,
			MV.Variant AS e_jlr_model_variant_description_text,
			API.e_jlr_party_id_int,
			C.Country AS e_jlr_country_name_auto,
			C.CountryID AS e_jlr_country_id_enum,
			API.e_jlr_customer_unique_id,
			API.LanguageID AS e_jlr_language_id_enum,
			API.e_jlr_gender_id_enum,
			API.EventTypeID AS e_jlr_event_type_id_enum,
			API.e_jlr_event_date,
			API.e_jlr_itype_enum,
			API.e_jlr_test_sample_yn,
			D.Outlet AS e_jlr_dealer_name_auto,
			D.OutletCode AS e_jlr_dealer_code_auto,
			D.Dealer10DigitCode AS e_jlr_global_dealer_code_auto,
			D.BusinessRegion AS e_jlr_business_region_auto,
			API.e_jlr_ownersip_cycle_auto,
			API.e_jlr_employee_code_text,
			CASE	WHEN LEN(API.e_jlr_employee_name_text) > 0 THEN CASE	WHEN LEN(D.PAGCode) > 0 THEN  API.e_jlr_employee_name_text + ' (' + D.PAGCode + ')'
																			ELSE API.e_jlr_employee_name_text END
					ELSE '' END AS e_jlr_employee_name_text,
			V.SVOTypeID AS e_jlr_svo_type_id_enum,
			ISNULL(D.SVODealer,'') AS e_jlr_svo_dealership_yn,
			V.FOBCode AS e_jlr_fob_code_enum,
			API.e_jlr_service_event_type_auto,
			API.EventID AS e_jlr_id_text,
			API.e_responsedate,
			CASE	WHEN PH.EngineDescription LIKE '%BEV%' THEN 1
					WHEN PH.EngineDescription LIKE '%PHEV%' THEN 2
					ELSE 0 END AS e_jlr_engine_type_enum,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_ltr_scale11) = 1 THEN API.q_jlr_sales_ltr_scale11 
					ELSE '' END AS q_jlr_sales_ltr_scale11,
			ISNULL(API.q_jlr_ltr_cmt,'') AS q_jlr_ltr_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_anonymous_yn) = 1 THEN API.q_jlr_anonymous_yn 
					ELSE '' END AS q_jlr_anonymous_yn,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_feel_welcome_scale11) = 1 THEN API.q_jlr_sales_feel_welcome_scale11 
					ELSE '' END AS q_jlr_sales_feel_welcome_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_showroom_app_scale11) = 1 THEN API.q_jlr_sales_showroom_app_scale11 
					ELSE '' END AS q_jlr_sales_showroom_app_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_understand_needs_scale11) = 1 THEN API.q_jlr_sales_understand_needs_scale11 
					ELSE '' END AS q_jlr_sales_understand_needs_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_test_drive_scale11) = 1 THEN API.q_jlr_sales_test_drive_scale11 
					ELSE '' END AS q_jlr_sales_test_drive_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_test_drive_alt) = 1 THEN API.q_jlr_sales_test_drive_alt 
					ELSE '' END AS q_jlr_sales_test_drive_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_accessories_offer_scale11) = 1 THEN API.q_jlr_sales_accessories_offer_scale11 
					ELSE '' END AS q_jlr_sales_accessories_offer_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_accessories_offer_sp_alt) = 1 THEN API.q_jlr_sales_accessories_offer_sp_alt 
					ELSE '' END AS q_jlr_sales_accessories_offer_sp_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_fs_offer_scale11na) = 1 THEN API.q_jlr_sales_fs_offer_scale11na 
					ELSE '' END AS q_jlr_sales_fs_offer_scale11na,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_fs_not_applicable_radio) = 1 THEN API.q_jlr_sales_fs_not_applicable_radio 
					ELSE '' END AS q_jlr_sales_fs_not_applicable_radio,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_delivery_time_scale11) = 1 THEN API.q_jlr_sales_delivery_time_scale11 
					ELSE '' END AS q_jlr_sales_delivery_time_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_handover_scale11) = 1 THEN API.q_jlr_sales_handover_scale11 
					ELSE '' END AS q_jlr_sales_handover_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_contact_scale11na) = 1 THEN API.q_jlr_sales_contact_scale11na 
					ELSE '' END AS q_jlr_sales_contact_scale11na,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_contact_sv_alt) = 1 THEN API.q_jlr_sales_contact_sv_alt 
					ELSE '' END AS q_jlr_sales_contact_sv_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_commitments_yn) = 1 THEN API.q_jlr_sales_commitments_yn 
					ELSE '' END AS q_jlr_sales_commitments_yn,
			ISNULL(API.q_jlr_sales_commitments_cmt,'') AS q_jlr_sales_commitments_cmt,
			CASE WHEN ISNULL(PH.EngineDescription,'') NOT LIKE '%BEV%' AND ISNULL(PH.EngineDescription,'') NOT LIKE '%PHEV%' THEN ''		-- V1.1
				 ELSE CASE	WHEN ISNUMERIC(API.q_jlr_sales_charging_explain_yn) = 1 THEN API.q_jlr_sales_charging_explain_yn 
							ELSE '' END END AS q_jlr_sales_charging_explain_yn,
			CASE WHEN ISNULL(PH.EngineDescription,'') NOT LIKE '%BEV%' AND ISNULL(PH.EngineDescription,'') NOT LIKE '%PHEV%' THEN ''		-- V1.1
				 ELSE CASE	WHEN ISNUMERIC(API.q_jlr_sales_homeinfo_scale11na) = 1 THEN API.q_jlr_sales_homeinfo_scale11na 
							ELSE '' END END AS q_jlr_sales_homeinfo_scale11na,
			CASE WHEN ISNULL(PH.EngineDescription,'') NOT LIKE '%BEV%' AND ISNULL(PH.EngineDescription,'') NOT LIKE '%PHEV%' THEN ''		-- V1.1
			 	 ELSE CASE	WHEN ISNUMERIC(API.q_jlr_sales_public_scale11na) = 1 THEN API.q_jlr_sales_public_scale11na 
							ELSE '' END END AS q_jlr_sales_public_scale11na,
			CASE WHEN ISNULL(PH.EngineDescription,'') NOT LIKE '%BEV%' AND ISNULL(PH.EngineDescription,'') NOT LIKE '%PHEV%' THEN ''		-- V1.1
				 ELSE CASE	WHEN ISNUMERIC(API.q_jlr_sales_install_scale11) = 1 THEN API.q_jlr_sales_install_scale11 
							ELSE '' END END AS q_jlr_sales_install_scale11,		
			CASE WHEN ISNULL(PH.EngineDescription,'') NOT LIKE '%BEV%' AND ISNULL(PH.EngineDescription,'') NOT LIKE '%PHEV%' THEN ''		-- V1.1
				 ELSE CASE	WHEN ISNUMERIC(API.q_jlr_sales_install_sv_alt) = 1 THEN API.q_jlr_sales_install_sv_alt 
							ELSE '' END END AS q_jlr_sales_install_sv_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_ltr_sc_scale11) = 1 THEN API.q_jlr_sales_ltr_sc_scale11 
					ELSE '' END AS q_jlr_sales_ltr_sc_scale11,			
			ISNULL(API.q_jlr_sales_ltr_sales_consultant_cmt,'') AS q_jlr_sales_ltr_sales_consultant_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_recommend_mention_yn) = 1 THEN API.q_jlr_sales_recommend_mention_yn 
					ELSE '' END AS q_jlr_sales_recommend_mention_yn,
			ISNULL(API.q_jlr_sales_recommend_mention_cmt,'') AS q_jlr_sales_recommend_mention_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_ltr_model_scale11) = 1 THEN API.q_jlr_sales_ltr_model_scale11 
					ELSE '' END AS q_jlr_sales_ltr_model_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_sales_furtherinfo_alt) = 1 THEN API.q_jlr_sales_furtherinfo_alt 
					ELSE '' END AS q_jlr_sales_furtherinfo_alt,
			ISNULL(API.q_jlr_sales_furtherinfo_arrival_cmt,'') AS q_jlr_sales_furtherinfo_arrival_cmt,
			ISNULL(API.q_jlr_sales_furtherinfo_at_retailer_cmt,'') AS q_jlr_sales_furtherinfo_at_retailer_cmt,
			ISNULL(API.q_jlr_sales_furtherinfo_collection_cmt,'') AS q_jlr_sales_furtherinfo_collection_cmt,
			ISNULL(API.q_jlr_sales_furtherinfo_delivery_cmt,'') AS q_jlr_sales_furtherinfo_delivery_cmt,
			ISNULL(API.q_jlr_sales_furtherinfo_recommendations_cmt,'') AS q_jlr_sales_furtherinfo_recommendations_cmt,
			ISNULL(API.q_jlr_sales_furtherinfo_vehicle_cmt,'') AS q_jlr_sales_furtherinfo_vehicle_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_ltr_scale11) = 1 THEN API.q_jlr_service_ltr_scale11 
					ELSE '' END AS q_jlr_service_ltr_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_booking_ease_scale11) = 1 THEN API.q_jlr_service_booking_ease_scale11 
					ELSE '' END AS q_jlr_service_booking_ease_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_osat_vehicle_seen_scale11) = 1 THEN API.q_jlr_service_osat_vehicle_seen_scale11 
					ELSE '' END AS q_jlr_service_osat_vehicle_seen_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_days_vehicle_seen_alt) = 1 THEN API.q_jlr_service_days_vehicle_seen_alt 
					ELSE '' END AS q_jlr_service_days_vehicle_seen_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_mobility_requirements_scale11) = 1 THEN API.q_jlr_service_mobility_requirements_scale11 
					ELSE '' END AS q_jlr_service_mobility_requirements_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_mobility_option_mvalt) = 1 THEN API.q_jlr_service_mobility_option_mvalt 
					ELSE '' END AS q_jlr_service_mobility_option_mvalt,
			ISNULL(API.q_jlr_service_other_mobility_cmt,'') AS q_jlr_service_other_mobility_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_feel_welcome_scale11) = 1 THEN API.q_jlr_service_feel_welcome_scale11 
					ELSE '' END AS q_jlr_service_feel_welcome_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_explanation_work_scale11) = 1 THEN API.q_jlr_service_explanation_work_scale11 
					ELSE '' END AS q_jlr_service_explanation_work_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_condition_scale11) = 1 THEN API.q_jlr_service_condition_scale11 
					ELSE '' END AS q_jlr_service_condition_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_fixed_right_yn) = 1 THEN API.q_jlr_service_fixed_right_yn 
					ELSE '' END AS q_jlr_service_fixed_right_yn,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_reason_fixed_right_alt) = 1 THEN API.q_jlr_service_reason_fixed_right_alt 
					ELSE '' END AS q_jlr_service_reason_fixed_right_alt,
			ISNULL(API.q_jlr_service_other_cmt,'') AS q_jlr_service_other_cmt,
			ISNULL(API.q_jlr_service_reason_fixed_right_cmt,'') AS q_jlr_service_reason_fixed_right_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_post_service_scale11) = 1 THEN API.q_jlr_post_service_scale11 
					ELSE '' END AS q_jlr_post_service_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_post_service_sv_alt) = 1 THEN API.q_jlr_post_service_sv_alt 
					ELSE '' END AS q_jlr_post_service_sv_alt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_osat_value_money_scale11) = 1 THEN API.q_jlr_service_osat_value_money_scale11 
					ELSE '' END AS q_jlr_service_osat_value_money_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_ltr_advisor_scale11) = 1 THEN API.q_jlr_service_ltr_advisor_scale11 
					ELSE '' END AS q_jlr_service_ltr_advisor_scale11,
			ISNULL(API.q_jlr_service_ltr_advisor_cmt,'') AS q_jlr_service_ltr_advisor_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_mention_other_yn) = 1 THEN API.q_jlr_service_mention_other_yn 
					ELSE '' END AS q_jlr_service_mention_other_yn,
			ISNULL(API.q_jlr_service_mention_other_cmt,'') AS q_jlr_service_mention_other_cmt,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_ltr_buy_lease_scale11) = 1 THEN API.q_jlr_service_ltr_buy_lease_scale11 
					ELSE '' END AS q_jlr_service_ltr_buy_lease_scale11,
			CASE	WHEN ISNUMERIC(API.q_jlr_service_furtherinfo_alt) = 1 THEN API.q_jlr_service_furtherinfo_alt 
					ELSE '' END AS q_jlr_service_furtherinfo_alt,
			ISNULL(API.q_jlr_service_furtherinfo_booking_cmt,'') AS q_jlr_service_furtherinfo_booking_cmt,
			ISNULL(API.q_jlr_service_furtherinfo_transport_cmt,'') AS q_jlr_service_furtherinfo_transport_cmt,
			ISNULL(API.q_jlr_service_furtherinfo_retailer_cmt,'') AS q_jlr_service_furtherinfo_retailer_cmt,
			ISNULL(API.q_jlr_service_furtherinfo_return_cmt,'') AS q_jlr_service_furtherinfo_return_cmt,
			ISNULL(API.q_jlr_service_furtherinfo_contact_cmt,'') AS q_jlr_service_furtherinfo_contact_cmt,
			ISNULL(API.q_jlr_service_furtherinfo_recommendations_cmt,'') AS q_jlr_service_furtherinfo_recommendations_cmt,
			NULL AS e_jlr_sub_brand_text		--V1.3
		FROM Stage.AsiaPacificImporters API
			INNER JOIN CTE_AuditItemIDs AI ON API.AuditItemID = AI.AuditItemID
			LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON API.VehicleID = V.VehicleID
			LEFT JOIN [$(SampleDB)].Vehicle.Models M ON V.ModelID = M.ModelID
			LEFT JOIN [$(SampleDB)].Vehicle.ModelVariants MV ON V.ModelVariantID = MV.VariantID
			LEFT JOIN [$(SampleDB)].dbo.Brands B ON M.ManufacturerPartyID = B.ManufacturerPartyID
			LEFT JOIN [$(SampleDB)].Vehicle.PHEVModels PH ON V.ModelID = PH.ModelID	
													AND LEFT(V.VIN,4) = PH.VINPrefix 
													AND SUBSTRING(V.VIN, 8, 1) = PH.VINCharacter
			LEFT JOIN CTE_ModelCodes MC ON V.ModelID = MC.ModelID
			LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON API.CountryID = C.CountryID
			LEFT JOIN [$(SampleDB)].dbo.Languages L ON API.LanguageID = L.LanguageID
			LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers D ON API.OutletPartyID = D.OutletPartyID
														AND API.OutletFunctionID = D.OutletFunctionID
		WHERE ISNULL(API.ValidatedData,0) = 1

		--V1.3
		UPDATE		API
		SET			e_jlr_sub_brand_text	= SB.SubBrand
		FROM		[$(SampleDB)].SelectionOutput.AsiaPacificImporters	API
		INNER JOIN  [$(SampleDB)].Vehicle.Models						MD ON API.ModelID	= MD.ModelID
		INNER JOIN  [$(SampleDB)].Vehicle.SubBrands						SB ON MD.SubBrandID = SB.SubBrandID	
	COMMIT TRAN

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
