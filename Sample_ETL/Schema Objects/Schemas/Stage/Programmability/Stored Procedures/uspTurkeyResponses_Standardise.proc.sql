CREATE PROCEDURE Stage.uspTurkeyResponses_Standardise

AS

/*
		Purpose:	Convert the supplied dates from a text string to a valid DATETIME type
	
		Version		Date			Developer			Comment
LIVE	1.0			2021-10-11		Chris Ledger		Created
LIVE	1.1			2021-11-29		Chris Ledger		Task 598 - recode q_jlr_service_days_vehicle_seen_alt DK from 99 to 33.
LIVE	1.2			2021-12-07		Chris Ledger		Task 598 - recode q_jlr_anonymous_yn from blank to 2.
LIVE	1.3			2022-03-09		Chris Ledger		Task 821 - Remove empty rows
*/

DECLARE @ErrorNumber			INT

DECLARE @ErrorSeverity			INT
DECLARE @ErrorState				INT
DECLARE @ErrorLocation			NVARCHAR(500)
DECLARE @ErrorLine				INT
DECLARE @ErrorMessage			NVARCHAR(2048)

SET LANGUAGE ENGLISH
BEGIN TRY

	---------------------------------------------------------------------------------------------------------
	-- TRIM DATA 
	---------------------------------------------------------------------------------------------------------
	UPDATE TR
	SET TR.e_jlr_case_id_text = RTRIM(LTRIM(TR.e_jlr_case_id_text)),
		TR.e_bp_uniquerecordid_txt = RTRIM(LTRIM(TR.e_bp_uniquerecordid_txt)),
		TR.e_jlr_survey_type_id_enum = RTRIM(LTRIM(TR.e_jlr_survey_type_id_enum)),
		TR.e_jlr_model_code_auto = RTRIM(LTRIM(TR.e_jlr_model_code_auto)),
		TR.e_jlr_model_description_text = RTRIM(LTRIM(TR.e_jlr_model_description_text)),
		TR.e_jlr_model_year_auto = RTRIM(LTRIM(TR.e_jlr_model_year_auto)),
		TR.e_jlr_manufacturer_id_enum = RTRIM(LTRIM(TR.e_jlr_manufacturer_id_enum)),
		TR.e_jlr_manufacturer_enum = RTRIM(LTRIM(TR.e_jlr_manufacturer_enum)),
		TR.e_jlr_car_registration_text = RTRIM(LTRIM(TR.e_jlr_car_registration_text)),
		TR.e_jlr_vehicle_identification_number_text = RTRIM(LTRIM(TR.e_jlr_vehicle_identification_number_text)),
		TR.e_jlr_model_variant_code_auto = RTRIM(LTRIM(TR.e_jlr_model_variant_code_auto)),
		TR.e_jlr_model_variant_description_text = RTRIM(LTRIM(TR.e_jlr_model_variant_description_text)),
		TR.e_jlr_party_id_int = RTRIM(LTRIM(TR.e_jlr_party_id_int)),
		TR.e_jlr_country_name_auto = RTRIM(LTRIM(TR.e_jlr_country_name_auto)),
		TR.e_jlr_country_id_enum = RTRIM(LTRIM(TR.e_jlr_country_id_enum)),
		TR.e_jlr_customer_unique_id = RTRIM(LTRIM(TR.e_jlr_customer_unique_id)),
		TR.e_jlr_language_id_enum = RTRIM(LTRIM(TR.e_jlr_language_id_enum)),
		TR.e_jlr_gender_id_enum = RTRIM(LTRIM(TR.e_jlr_gender_id_enum)),
		TR.e_jlr_event_type_id_enum = RTRIM(LTRIM(TR.e_jlr_event_type_id_enum)),
		TR.e_jlr_event_date = RTRIM(LTRIM(TR.e_jlr_event_date)),
		TR.e_jlr_itype_enum = RTRIM(LTRIM(TR.e_jlr_itype_enum)),
		TR.e_jlr_test_sample_yn = RTRIM(LTRIM(TR.e_jlr_test_sample_yn)),
		TR.e_jlr_dealer_name_auto = RTRIM(LTRIM(TR.e_jlr_dealer_name_auto)),
		TR.e_jlr_dealer_code_auto = RTRIM(LTRIM(TR.e_jlr_dealer_code_auto)),
		TR.e_jlr_global_dealer_code_auto = RTRIM(LTRIM(TR.e_jlr_global_dealer_code_auto)),
		TR.e_jlr_business_region_auto = RTRIM(LTRIM(TR.e_jlr_business_region_auto)),
		TR.e_jlr_ownersip_cycle_auto = RTRIM(LTRIM(TR.e_jlr_ownersip_cycle_auto)),
		TR.e_jlr_employee_code_text = RTRIM(LTRIM(TR.e_jlr_employee_code_text)),
		TR.e_jlr_employee_name_text = RTRIM(LTRIM(TR.e_jlr_employee_name_text)),
		TR.e_jlr_svo_type_id_enum = RTRIM(LTRIM(TR.e_jlr_svo_type_id_enum)),
		TR.e_jlr_svo_dealership_yn = RTRIM(LTRIM(TR.e_jlr_svo_dealership_yn)),
		TR.e_jlr_fob_code_enum = RTRIM(LTRIM(TR.e_jlr_fob_code_enum)),
		TR.e_jlr_service_event_type_auto = RTRIM(LTRIM(TR.e_jlr_service_event_type_auto)),
		TR.e_jlr_id_text = RTRIM(LTRIM(TR.e_jlr_id_text)),
		TR.e_responsedate = RTRIM(LTRIM(TR.e_responsedate)),
		TR.e_jlr_engine_type_enum = RTRIM(LTRIM(TR.e_jlr_engine_type_enum)),
		TR.q_jlr_sales_ltr_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_ltr_scale11)),
		TR.q_jlr_ltr_cmt = RTRIM(LTRIM(TR.q_jlr_ltr_cmt)),
		TR.q_jlr_anonymous_yn = RTRIM(LTRIM(TR.q_jlr_anonymous_yn)),
		TR.q_jlr_sales_feel_welcome_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_feel_welcome_scale11)),
		TR.q_jlr_sales_showroom_app_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_showroom_app_scale11)),
		TR.q_jlr_sales_understand_needs_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_understand_needs_scale11)),
		TR.q_jlr_sales_test_drive_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_test_drive_scale11)),
		TR.q_jlr_sales_test_drive_alt = RTRIM(LTRIM(TR.q_jlr_sales_test_drive_alt)),
		TR.q_jlr_sales_accessories_offer_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_accessories_offer_scale11)),
		TR.q_jlr_sales_accessories_offer_sp_alt = RTRIM(LTRIM(TR.q_jlr_sales_accessories_offer_sp_alt)),
		TR.q_jlr_sales_fs_offer_scale11na = RTRIM(LTRIM(TR.q_jlr_sales_fs_offer_scale11na)),
		TR.q_jlr_sales_fs_not_applicable_radio = RTRIM(LTRIM(TR.q_jlr_sales_fs_not_applicable_radio)),
		TR.q_jlr_sales_delivery_time_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_delivery_time_scale11)),
		TR.q_jlr_sales_handover_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_handover_scale11)),
		TR.q_jlr_sales_contact_scale11na = RTRIM(LTRIM(TR.q_jlr_sales_contact_scale11na)),
		TR.q_jlr_sales_contact_sv_alt = RTRIM(LTRIM(TR.q_jlr_sales_contact_sv_alt)),
		TR.q_jlr_sales_commitments_yn = RTRIM(LTRIM(TR.q_jlr_sales_commitments_yn)),
		TR.q_jlr_sales_commitments_cmt = RTRIM(LTRIM(TR.q_jlr_sales_commitments_cmt)),
		TR.q_jlr_sales_charging_explain_yn = RTRIM(LTRIM(TR.q_jlr_sales_charging_explain_yn)),
		TR.q_jlr_sales_homeinfo_scale11na = RTRIM(LTRIM(TR.q_jlr_sales_homeinfo_scale11na)),
		TR.q_jlr_sales_public_scale11na = RTRIM(LTRIM(TR.q_jlr_sales_public_scale11na)),
		TR.q_jlr_sales_install_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_install_scale11)),
		TR.q_jlr_sales_install_sv_alt = RTRIM(LTRIM(TR.q_jlr_sales_install_sv_alt)),
		TR.q_jlr_sales_ltr_sc_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_ltr_sc_scale11)),
		TR.q_jlr_sales_ltr_sales_consultant_cmt = RTRIM(LTRIM(TR.q_jlr_sales_ltr_sales_consultant_cmt)),
		TR.q_jlr_sales_recommend_mention_yn = RTRIM(LTRIM(TR.q_jlr_sales_recommend_mention_yn)),
		TR.q_jlr_sales_recommend_mention_cmt = RTRIM(LTRIM(TR.q_jlr_sales_recommend_mention_cmt)),
		TR.q_jlr_sales_ltr_model_scale11 = RTRIM(LTRIM(TR.q_jlr_sales_ltr_model_scale11)),
		TR.q_jlr_sales_furtherinfo_alt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_alt)),
		TR.q_jlr_sales_furtherinfo_arrival_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_arrival_cmt)),
		TR.q_jlr_sales_furtherinfo_at_retailer_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_at_retailer_cmt)),
		TR.q_jlr_sales_furtherinfo_collection_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_collection_cmt)),
		TR.q_jlr_sales_furtherinfo_delivery_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_delivery_cmt)),
		TR.q_jlr_sales_furtherinfo_recommendations_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_recommendations_cmt)),
		TR.q_jlr_sales_furtherinfo_vehicle_cmt = RTRIM(LTRIM(TR.q_jlr_sales_furtherinfo_vehicle_cmt)),
		TR.q_jlr_service_ltr_scale11 = RTRIM(LTRIM(TR.q_jlr_service_ltr_scale11)),
		TR.q_jlr_service_booking_ease_scale11 = RTRIM(LTRIM(TR.q_jlr_service_booking_ease_scale11)),
		TR.q_jlr_service_osat_vehicle_seen_scale11 = RTRIM(LTRIM(TR.q_jlr_service_osat_vehicle_seen_scale11)),
		TR.q_jlr_service_days_vehicle_seen_alt = RTRIM(LTRIM(TR.q_jlr_service_days_vehicle_seen_alt)),
		TR.q_jlr_service_mobility_requirements_scale11 = RTRIM(LTRIM(TR.q_jlr_service_mobility_requirements_scale11)),
		TR.q_jlr_service_mobility_option_mvalt = RTRIM(LTRIM(TR.q_jlr_service_mobility_option_mvalt)),
		TR.q_jlr_service_other_mobility_cmt = RTRIM(LTRIM(TR.q_jlr_service_other_mobility_cmt)),
		TR.q_jlr_service_feel_welcome_scale11 = RTRIM(LTRIM(TR.q_jlr_service_feel_welcome_scale11)),
		TR.q_jlr_service_explanation_work_scale11 = RTRIM(LTRIM(TR.q_jlr_service_explanation_work_scale11)),
		TR.q_jlr_service_condition_scale11 = RTRIM(LTRIM(TR.q_jlr_service_condition_scale11)),
		TR.q_jlr_service_fixed_right_yn = RTRIM(LTRIM(TR.q_jlr_service_fixed_right_yn)),
		TR.q_jlr_service_reason_fixed_right_alt = RTRIM(LTRIM(TR.q_jlr_service_reason_fixed_right_alt)),
		TR.q_jlr_service_other_cmt = RTRIM(LTRIM(TR.q_jlr_service_other_cmt)),
		TR.q_jlr_service_reason_fixed_right_cmt = RTRIM(LTRIM(TR.q_jlr_service_reason_fixed_right_cmt)),
		TR.q_jlr_post_service_scale11 = RTRIM(LTRIM(TR.q_jlr_post_service_scale11)),
		TR.q_jlr_post_service_sv_alt = RTRIM(LTRIM(TR.q_jlr_post_service_sv_alt)),
		TR.q_jlr_service_osat_value_money_scale11 = RTRIM(LTRIM(TR.q_jlr_service_osat_value_money_scale11)),
		TR.q_jlr_service_ltr_advisor_scale11 = RTRIM(LTRIM(TR.q_jlr_service_ltr_advisor_scale11)),
		TR.q_jlr_service_ltr_advisor_cmt = RTRIM(LTRIM(TR.q_jlr_service_ltr_advisor_cmt)),
		TR.q_jlr_service_mention_other_yn = RTRIM(LTRIM(TR.q_jlr_service_mention_other_yn)),
		TR.q_jlr_service_mention_other_cmt = RTRIM(LTRIM(TR.q_jlr_service_mention_other_cmt)),
		TR.q_jlr_service_ltr_buy_lease_scale11 = RTRIM(LTRIM(TR.q_jlr_service_ltr_buy_lease_scale11)),
		TR.q_jlr_service_furtherinfo_alt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_alt)),
		TR.q_jlr_service_furtherinfo_booking_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_booking_cmt)),
		TR.q_jlr_service_furtherinfo_transport_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_transport_cmt)),
		TR.q_jlr_service_furtherinfo_retailer_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_retailer_cmt)),
		TR.q_jlr_service_furtherinfo_return_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_return_cmt)),
		TR.q_jlr_service_furtherinfo_contact_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_contact_cmt)),
		TR.q_jlr_service_furtherinfo_recommendations_cmt = RTRIM(LTRIM(TR.q_jlr_service_furtherinfo_recommendations_cmt))
	FROM Stage.TurkeyResponses TR
	---------------------------------------------------------------------------------------------------------


	---------------------------------------------------------------------------------------------------------
	-- V1.3 Remove blank rows  
	---------------------------------------------------------------------------------------------------------
	DELETE FROM TR
	FROM Stage.TurkeyResponses TR
	WHERE LEN(TR.e_jlr_case_id_text) = 0 AND LEN(TR.e_bp_uniquerecordid_txt) = 0 AND LEN(TR.e_jlr_survey_type_id_enum) = 0 AND LEN(TR.e_jlr_model_code_auto) = 0 AND LEN(TR.e_jlr_model_description_text) = 0 AND LEN(TR.e_jlr_model_year_auto) = 0 AND LEN(TR.e_jlr_manufacturer_id_enum) = 0 AND LEN(TR.e_jlr_manufacturer_enum) = 0 AND LEN(TR.e_jlr_car_registration_text) = 0 AND LEN(TR.e_jlr_vehicle_identification_number_text) = 0 AND LEN(TR.e_jlr_model_variant_code_auto) = 0 AND LEN(TR.e_jlr_model_variant_description_text) = 0 AND LEN(TR.e_jlr_party_id_int) = 0 AND LEN(TR.e_jlr_country_name_auto) = 0 AND LEN(TR.e_jlr_country_id_enum) = 0 AND LEN(TR.e_jlr_customer_unique_id) = 0 AND LEN(TR.e_jlr_language_id_enum) = 0 AND LEN(TR.e_jlr_gender_id_enum) = 0 AND LEN(TR.e_jlr_event_type_id_enum) = 0 AND LEN(TR.e_jlr_event_date) = 0 AND LEN(TR.e_jlr_itype_enum) = 0 AND LEN(TR.e_jlr_test_sample_yn) = 0 AND LEN(TR.e_jlr_dealer_name_auto) = 0 AND LEN(TR.e_jlr_dealer_code_auto) = 0 AND LEN(TR.e_jlr_global_dealer_code_auto) = 0 AND LEN(TR.e_jlr_business_region_auto) = 0 AND LEN(TR.e_jlr_ownersip_cycle_auto) = 0 AND LEN(TR.e_jlr_employee_code_text) = 0 AND LEN(TR.e_jlr_employee_name_text) = 0 AND LEN(TR.e_jlr_svo_type_id_enum) = 0 AND LEN(TR.e_jlr_svo_dealership_yn) = 0 AND LEN(TR.e_jlr_fob_code_enum) = 0 AND LEN(TR.e_jlr_service_event_type_auto) = 0 
	---------------------------------------------------------------------------------------------------------

	---------------------------------------------------------------------------------------------------------
	-- Convert Dates  
	---------------------------------------------------------------------------------------------------------
	UPDATE	Stage.TurkeyResponses
	SET		e_jlr_event_date_converted = CONVERT(DATETIME, e_jlr_event_date, 112)
	WHERE	ISDATE(e_jlr_event_date) = 1

	UPDATE	Stage.TurkeyResponses
	SET		e_responsedate_converted = CONVERT(DATETIME, e_responsedate, 120)
	WHERE	ISDATE(e_responsedate) = 1
	---------------------------------------------------------------------------------------------------------	


	---------------------------------------------------------------------------------------------------------
	-- V1.1 Recode q_jlr_service_days_vehicle_seen_alt DK from 99 to 33  
	---------------------------------------------------------------------------------------------------------
	UPDATE TR SET TR.q_jlr_service_days_vehicle_seen_alt = '33'
	FROM Stage.TurkeyResponses TR
	WHERE TR.q_jlr_service_days_vehicle_seen_alt = '99'
	---------------------------------------------------------------------------------------------------------	


	---------------------------------------------------------------------------------------------------------
	-- V1.2 Recode q_jlr_anonymous_yn from blank to 2  
	---------------------------------------------------------------------------------------------------------
	UPDATE TR SET TR.q_jlr_anonymous_yn = '2'
	FROM Stage.TurkeyResponses TR
	WHERE TR.q_jlr_anonymous_yn <> '1'
	---------------------------------------------------------------------------------------------------------	

END TRY
BEGIN CATCH

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
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.TurkeyResponses_' + @TimestampString + '
		FROM Stage.TurkeyResponses
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH