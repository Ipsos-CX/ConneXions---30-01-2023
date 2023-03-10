CREATE VIEW SelectionOutput.vwTurkeyResponses

AS 

/*
		Purpose:	Turkey Response output for Medallia
	
		Version			Date			Developer			Comment
LIVE	1.0				2021-10-13		Chris Ledger		Created
LIVE	1.1				2022-09-13		Eddie Thomas		TASK 1017 - Added SubBrand
*/

SELECT TR.e_jlr_case_id_text,
	TR.e_bp_uniquerecordid_txt,
	TR.e_jlr_survey_type_id_enum,
	TR.e_jlr_model_code_auto,
	TR.e_jlr_model_description_text,
	TR.e_jlr_model_year_auto,
	TR.e_jlr_manufacturer_id_enum,
	TR.e_jlr_manufacturer_enum,
	TR.e_jlr_car_registration_text,
	TR.e_jlr_vehicle_identification_number_text,
	TR.e_jlr_model_variant_code_auto,
	TR.e_jlr_model_variant_description_text,
	TR.e_jlr_party_id_int,
	TR.e_jlr_country_name_auto,
	TR.e_jlr_country_id_enum,
	TR.e_jlr_customer_unique_id,
	TR.e_jlr_language_id_enum,
	TR.e_jlr_gender_id_enum,
	TR.e_jlr_event_type_id_enum,
	TR.e_jlr_event_date,
	TR.e_jlr_itype_enum,
	TR.e_jlr_test_sample_yn,
	TR.e_jlr_dealer_name_auto,
	TR.e_jlr_dealer_code_auto,
	TR.e_jlr_global_dealer_code_auto,
	TR.e_jlr_business_region_auto,
	TR.e_jlr_ownersip_cycle_auto,
	TR.e_jlr_employee_code_text,
	TR.e_jlr_employee_name_text,
	ISNULL(TR.e_jlr_svo_type_id_enum,0) AS e_jlr_svo_type_id_enum,
	TR.e_jlr_svo_dealership_yn,
	TR.e_jlr_fob_code_enum,
	TR.e_jlr_service_event_type_auto AS e_jlr_service_event_type_auto,
	TR.e_jlr_id_text,
	TR.e_responsedate,
	TR.e_jlr_engine_type_enum,
	TR.q_jlr_sales_ltr_scale11,
	TR.q_jlr_ltr_cmt,
	TR.q_jlr_anonymous_yn,
	TR.q_jlr_sales_feel_welcome_scale11,
	TR.q_jlr_sales_showroom_app_scale11,
	TR.q_jlr_sales_understand_needs_scale11,
	TR.q_jlr_sales_test_drive_scale11,
	TR.q_jlr_sales_test_drive_alt,
	TR.q_jlr_sales_accessories_offer_scale11,
	TR.q_jlr_sales_accessories_offer_sp_alt,
	TR.q_jlr_sales_fs_offer_scale11na,
	TR.q_jlr_sales_fs_not_applicable_radio,
	TR.q_jlr_sales_delivery_time_scale11,
	TR.q_jlr_sales_handover_scale11,
	TR.q_jlr_sales_contact_scale11na,
	TR.q_jlr_sales_contact_sv_alt,
	TR.q_jlr_sales_commitments_yn,
	TR.q_jlr_sales_commitments_cmt,
	TR.q_jlr_sales_charging_explain_yn,
	TR.q_jlr_sales_homeinfo_scale11na,
	TR.q_jlr_sales_public_scale11na,
	TR.q_jlr_sales_install_scale11,
	TR.q_jlr_sales_install_sv_alt,
	TR.q_jlr_sales_ltr_sc_scale11,
	TR.q_jlr_sales_ltr_sales_consultant_cmt,
	TR.q_jlr_sales_recommend_mention_yn,
	TR.q_jlr_sales_recommend_mention_cmt,
	TR.q_jlr_sales_ltr_model_scale11,
	TR.q_jlr_sales_furtherinfo_alt,
	TR.q_jlr_sales_furtherinfo_arrival_cmt,
	TR.q_jlr_sales_furtherinfo_at_retailer_cmt,
	TR.q_jlr_sales_furtherinfo_collection_cmt,
	TR.q_jlr_sales_furtherinfo_delivery_cmt,
	TR.q_jlr_sales_furtherinfo_recommendations_cmt,
	TR.q_jlr_sales_furtherinfo_vehicle_cmt,
	TR.q_jlr_service_ltr_scale11,
	TR.q_jlr_service_booking_ease_scale11,
	TR.q_jlr_service_osat_vehicle_seen_scale11,
	TR.q_jlr_service_days_vehicle_seen_alt,
	TR.q_jlr_service_mobility_requirements_scale11,
	TR.q_jlr_service_mobility_option_mvalt,
	TR.q_jlr_service_other_mobility_cmt,
	TR.q_jlr_service_feel_welcome_scale11,
	TR.q_jlr_service_explanation_work_scale11,
	TR.q_jlr_service_condition_scale11,
	TR.q_jlr_service_fixed_right_yn,
	TR.q_jlr_service_reason_fixed_right_alt,
	TR.q_jlr_service_other_cmt,
	TR.q_jlr_service_reason_fixed_right_cmt,
	TR.q_jlr_post_service_scale11,
	TR.q_jlr_post_service_sv_alt,
	TR.q_jlr_service_osat_value_money_scale11,
	TR.q_jlr_service_ltr_advisor_scale11,
	TR.q_jlr_service_ltr_advisor_cmt,
	TR.q_jlr_service_mention_other_yn,
	TR.q_jlr_service_mention_other_cmt,
	TR.q_jlr_service_ltr_buy_lease_scale11,
	TR.q_jlr_service_furtherinfo_alt,
	TR.q_jlr_service_furtherinfo_booking_cmt,
	TR.q_jlr_service_furtherinfo_transport_cmt,
	TR.q_jlr_service_furtherinfo_retailer_cmt,
	TR.q_jlr_service_furtherinfo_return_cmt,
	TR.q_jlr_service_furtherinfo_contact_cmt,
	TR.q_jlr_service_furtherinfo_recommendations_cmt,
	TR.e_jlr_sub_brand_text			--v1.1
FROM SelectionOutput.TurkeyResponses TR
WHERE TR.ValidatedData = 1
	AND TR.OutputToMedalliaDate IS NULL

GO
