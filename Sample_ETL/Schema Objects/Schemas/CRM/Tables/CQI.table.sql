CREATE TABLE [CRM].[CQI](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[VWTID] [dbo].[VWTID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NOT NULL,
	[EventTypeID] [int] NULL,
	[Converted_ACCT_DATE_OF_BIRTH] [datetime2] (7) NULL,
	[Converted_ACCT_DATE_ADVISED_OF_DEATH] [datetime2] (7) NULL,
	[Converted_VEH_REGISTRATION_DATE] [datetime2] (7) NULL,
	[Converted_VEH_BUILD_DATE] [datetime2] (7) NULL,
	[Converted_DMS_REPAIR_ORDER_CLOSED_DATE] [datetime2] (7) NULL,
	[Converted_ROADSIDE_DATE_JOB_COMPLETED] [datetime2] (7) NULL,
	[Converted_CASE_CASE_SOLVED_DATE] [datetime2] (7) NULL,
	[Converted_VISTACONTRACT_HANDOVER_DATE] [datetime2] (7) NULL,
	[DateTransferredToVWT] [datetime2](7) NULL, 
	[SampleTriggeredSelectionReqID] int		 NULL,
	Calculated_Salutation  nvarchar(510) NULL,					-- BUG 16731
	Calculated_Title  nvarchar(510) NULL,						-- BUG 16731
	
	[AFRLCode]				[dbo].[LoadText] NULL,

	item_Id							INT NULL,					-- TASK 502
	ACCT_ACADEMIC_TITLE       nvarchar(40)     NULL,
	ACCT_ACADEMIC_TITLE_CODE       nvarchar(4)     NULL,
	ACCT_ACCT_ID       nvarchar(10)     NULL,
	ACCT_ACCT_TYPE       nvarchar(60)     NULL,
	ACCT_ACCT_TYPE_CODE       nvarchar(1)     NULL,
	ACCT_ADDITIONAL_LAST_NAME       nvarchar(40)     NULL,
	ACCT_BP_ROLE		nvarchar(255)	 NULL,
	ACCT_BUILDING       nvarchar(20)     NULL,
	ACCT_CITY_CODE       nvarchar(12)     NULL,
	ACCT_CITY_CODE2       nvarchar(12)     NULL,
	ACCT_CITY_TOWN       nvarchar(40)     NULL,
	ACCT_CITYH_CODE       nvarchar(12)     NULL,
	ACCT_CONSENT_JAGUAR_EMAIL       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PHONE       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_POST       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_EMAIL       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_POST       nvarchar(60)     NULL,
	ACCT_CONSENT_LR_PHONE       nvarchar(60)     NULL,
	ACCT_CORRESPONDENCE_LANG_CODE       nvarchar(2)     NULL,
	ACCT_CORRESPONDENCE_LANGUAGE       nvarchar(16)     NULL,
	ACCT_COUNTRY       nvarchar(50)     NULL,
	ACCT_COUNTRY_CODE       nvarchar(3)     NULL,
	ACCT_COUNTY       nvarchar(40)     NULL,
	ACCT_COUNTY_CODE       nvarchar(8)     NULL,
	ACCT_DATE_ADVISED_OF_DEATH       nvarchar(10)     NULL,
	ACCT_DATE_DECL_TO_GIVE_EMAIL       nvarchar(10)     NULL,
	ACCT_DATE_OF_BIRTH       nvarchar(10)     NULL,
	ACCT_DEAL_FULNAME_OF_CREAT_DEA       nvarchar(81)     NULL,
	ACCT_DISTRICT       nvarchar(8)     NULL,
	ACCT_EMAIL_VALIDATION_STATUS       nvarchar(30)     NULL,
	ACCT_EMPLOYER_NAME       nvarchar(35)     NULL,
	ACCT_EXTERN_FINANC_COMP_ACCTID       nvarchar(60)     NULL,
	ACCT_FIRST_NAME       nvarchar(40)     NULL,
	ACCT_FLOOR       nvarchar(10)     NULL,
	ACCT_FULL_NAME       nvarchar(81)     NULL,
	ACCT_GENDER_FEMALE       nvarchar(1)     NULL,
	ACCT_GENDER_MALE       nvarchar(1)     NULL,
	ACCT_GENDER_UNKNOWN       nvarchar(1)     NULL,
	ACCT_GENERATION       nvarchar(5)     NULL,
--	ACCT_GERMAN_ONLY_NON_ACAD_CODE       nvarchar(4)     NULL,				-- Removed with SC00146 version 5.7 (see BUG 16755)
--	ACCT_GERMAN_ONLY_NON_ACADEMIC       nvarchar(80)     NULL,				-- Removed with SC00146 version 5.7 (see BUG 16755)
	ACCT_HOME_CITY       nvarchar(40)     NULL,
	ACCT_HOME_EMAIL_ADDR_PRIMARY       nvarchar(241)     NULL,
	ACCT_HOME_PHONE_NUMBER       nvarchar(30)     NULL,
	ACCT_HOUSE_NO       nvarchar(10)     NULL,
	ACCT_HOUSE_NUM2       nvarchar(10)     NULL,
	ACCT_HOUSE_NUM3       nvarchar(10)     NULL,
	ACCT_INDUSTRY_SECTOR       nvarchar(20)     NULL,
	ACCT_INDUSTRY_SECTOR_CODE       nvarchar(10)     NULL,
	ACCT_INITIALS       nvarchar(10)     NULL,
	ACCT_JAGUAR_IN_MARKET_DATE       nvarchar(10)     NULL,
	ACCT_JAGUAR_LOYALTY_STATUS       nvarchar(25)     NULL,
	ACCT_KNOWN_AS       nvarchar(40)     NULL,
	ACCT_LAND_ROVER_LOYALTY_STATUS       nvarchar(25)     NULL,
	ACCT_LAND_ROVER_MARKET_DATE       nvarchar(10)     NULL,
	ACCT_LAST_NAME       nvarchar(40)     NULL,
	ACCT_LOCATION       nvarchar(40)     NULL,
	ACCT_MIDDLE_NAME       nvarchar(40)     NULL,
	ACCT_MOBILE_NUMBER       nvarchar(30)     NULL,
	ACCT_NAME_1       nvarchar(40)     NULL,
	ACCT_NAME_2       nvarchar(40)     NULL,
	ACCT_NAME_3       nvarchar(40)     NULL,
	ACCT_NAME_4       nvarchar(40)     NULL,
	ACCT_NAME_CO       nvarchar(40)     NULL,
	ACCT_NON_ACADEMIC_TITLE       nvarchar(80)     NULL,
	ACCT_NON_ACADEMIC_TITLE_CODE       nvarchar(4)     NULL,
	ACCT_ORG_TYPE       nvarchar(40)     NULL,
	ACCT_ORG_TYPE_CODE       nvarchar(4)     NULL,
	ACCT_PCODE1_EXT       nvarchar(10)     NULL,
	ACCT_PCODE2_EXT       nvarchar(10)     NULL,
	ACCT_PCODE3_EXT       nvarchar(10)     NULL,
	ACCT_PO_BOX       nvarchar(10)     NULL,
	ACCT_PO_BOX_CTY       nvarchar(3)     NULL,
	ACCT_PO_BOX_LOBBY       nvarchar(40)     NULL,
	ACCT_PO_BOX_LOC       nvarchar(40)     NULL,
	ACCT_PO_BOX_NUM       nvarchar(1)     NULL,
	ACCT_PO_BOX_REG       nvarchar(3)     NULL,
	ACCT_POST_CODE2       nvarchar(10)     NULL,
	ACCT_POST_CODE3       nvarchar(10)     NULL,
	ACCT_POSTALAREA       nvarchar(15)     NULL,
	ACCT_POSTCODE_ZIP       nvarchar(10)     NULL,
	ACCT_PREF_CONTACT_METHOD       nvarchar(20)     NULL,
	ACCT_PREF_CONTACT_METHOD_CODE       nvarchar(3)     NULL,
	ACCT_PREF_CONTACT_TIME       nvarchar(30)     NULL,
	ACCT_PREF_LANGUAGE       nvarchar(16)     NULL,
	ACCT_PREF_LANGUAGE_CODE       nvarchar(2)     NULL,
--	ACCT_PREFIX_1       nvarchar(40)     NULL,
--	ACCT_PREFIX_2       nvarchar(40)     NULL,
	ACCT_REGION_STATE       nvarchar(25)     NULL,
	ACCT_REGION_STATE_CODE       nvarchar(3)     NULL,
	ACCT_ROOM_NUMBER       nvarchar(10)     NULL,
	ACCT_STREET       nvarchar(60)     NULL,
	ACCT_STREETABBR       nvarchar(2)     NULL,
	ACCT_STREETCODE       nvarchar(12)     NULL,
	ACCT_SUPPLEMENT_1       nvarchar(40)     NULL,
	ACCT_SUPPLEMENT_2       nvarchar(40)     NULL,
	ACCT_SUPPLEMENT_3       nvarchar(40)     NULL,
	ACCT_TITLE       nvarchar(30)     NULL,
	ACCT_TITLE_CODE       nvarchar(4)     NULL,
	ACCT_TOWNSHIP       nvarchar(40)     NULL,
	ACCT_TOWNSHIP_CODE       nvarchar(8)     NULL,
	ACCT_VIP_FLAG       nvarchar(1)     NULL,
	ACCT_WORK_PHONE_EXTENSION       nvarchar(10)     NULL,
	ACCT_WORK_PHONE_PRIMARY       nvarchar(30)     NULL,
	ACTIVITY_ID       nvarchar(12)     NULL,
	CAMPAIGN_CAMPAIGN_CHANNEL       nvarchar(40)     NULL,
	CAMPAIGN_CAMPAIGN_DESC       nvarchar(40)     NULL,
	CAMPAIGN_CAMPAIGN_ID       nvarchar(24)     NULL,
	CAMPAIGN_CATEGORY_1       nvarchar(24)     NULL,
	CAMPAIGN_CATEGORY_2       nvarchar(40)     NULL,
	CAMPAIGN_CATEGORY_3       nvarchar(40)     NULL,
	CAMPAIGN_DEALERFULNAME_DEALER1       nvarchar(81)     NULL,
	CAMPAIGN_DEALERFULNAME_DEALER2       nvarchar(81)     NULL,
	CAMPAIGN_DEALERFULNAME_DEALER3       nvarchar(81)     NULL,
	CAMPAIGN_DEALERFULNAME_DEALER4       nvarchar(81)     NULL,
	CAMPAIGN_DEALERFULNAME_DEALER5       nvarchar(81)     NULL,
	CAMPAIGN_SECDEALERCODE_DEALER1       nvarchar(60)     NULL,
	CAMPAIGN_SECDEALERCODE_DEALER2       nvarchar(60)     NULL,
	CAMPAIGN_SECDEALERCODE_DEALER3       nvarchar(60)     NULL,
	CAMPAIGN_SECDEALERCODE_DEALER4       nvarchar(60)     NULL,
	CAMPAIGN_SECDEALERCODE_DEALER5       nvarchar(60)     NULL,
	CAMPAIGN_TARGET_GROUP_DESC       nvarchar(72)     NULL,
	CAMPAIGN_TARGET_GROUP_ID       nvarchar(10)     NULL,
	CASE_BRAND       nvarchar(20)     NULL,
	CASE_BRAND_CODE       nvarchar(20)     NULL,
	CASE_CASE_CREATION_DATE       nvarchar(10)     NULL,
	CASE_CASE_DESC       nvarchar(40)     NULL,
	CASE_CASE_EMPL_RESPONSIBLE_NAM       nvarchar(81)     NULL,
	CASE_CASE_ID       nvarchar(10)     NULL,
	CASE_CASE_SOLVED_DATE       nvarchar(10)     NULL,
	CASE_EMPL_RESPONSIBLE_ID       nvarchar(10)     NULL,
	CASE_GOODWILL_INDICATOR       nvarchar(1)     NULL,
	CASE_REASON_FOR_STATUS       nvarchar(60)     NULL,
	CASE_SECON_DEALER_CODE_OF_DEAL       nvarchar(60)     NULL,
	CASE_VEH_REG_PLATE       nvarchar(35)     NULL,
	CASE_VEH_VIN_NUMBER       nvarchar(35)     NULL,
	CASE_VEHMODEL_DERIVED_FROM_VIN       nvarchar(40)     NULL,
	CR_OBJECT_ID       nvarchar(10)     NULL,
	CRH_DEALER_ROA_CITY_TOWN       nvarchar(40)     NULL,
	CRH_DEALER_ROA_COUNTRY       nvarchar(50)     NULL,
	CRH_DEALER_ROA_HOUSE_NO       nvarchar(10)     NULL,
	CRH_DEALER_ROA_ID       nvarchar(10)     NULL,
	CRH_DEALER_ROA_NAME_1       nvarchar(40)     NULL,
	CRH_DEALER_ROA_NAME_2       nvarchar(40)     NULL,
	CRH_DEALER_ROA_PO_BOX       nvarchar(10)     NULL,
	CRH_DEALER_ROA_POSTCODE_ZIP       nvarchar(10)     NULL,
	CRH_DEALER_ROA_PREFIX_1       nvarchar(40)     NULL,
	CRH_DEALER_ROA_PREFIX_2       nvarchar(40)     NULL,
	CRH_DEALER_ROA_REGION_STATE       nvarchar(20)     NULL,
	CRH_DEALER_ROA_STREET       nvarchar(60)     NULL,
	CRH_DEALER_ROA_SUPPLEMENT_1       nvarchar(40)     NULL,
	CRH_DEALER_ROA_SUPPLEMENT_2       nvarchar(40)     NULL,
	CRH_DEALER_ROA_SUPPLEMENT_3       nvarchar(40)     NULL,
	CRH_END_DATE       nvarchar(10)     NULL,
	CRH_START_DATE       nvarchar(10)     NULL,
	DMS_ACTIVITY_DESC       nvarchar(40)     NULL,
	DMS_DAYS_OPEN       nvarchar(5)     NULL,
	DMS_EVENT_TYPE       nvarchar(15)     NULL,
	DMS_LICENSE_PLATE_REGISTRATION       nvarchar(35)     NULL,
	DMS_POTENTIAL_CHANGE_OF_OWNERS       nvarchar(5)     NULL,
	DMS_REPAIR_ORDER_CLOSED_DATE       nvarchar(10)     NULL,
	DMS_REPAIR_ORDER_NUMBER       nvarchar(20)     NULL,
	DMS_REPAIR_ORDER_OPEN_DATE       nvarchar(10)     NULL,
	DMS_SECON_DEALER_CODE       nvarchar(60)     NULL,
	DMS_SERVICE_ADVISOR       nvarchar(30)     NULL,
	DMS_SERVICE_ADVISOR_ID       nvarchar(15)     NULL,

	DMS_TECHNICIAN_ID			nvarchar(15) NULL,			-- BUG 13313 - 09/11/2016
	DMS_TECHNICIAN				nvarchar(30) NULL,			-- BUG 13313 - 09/11/2016

	DMS_TOTAL_CUSTOMER_PRICE       decimal(17)     NULL,
	DMS_USER_STATUS       nvarchar(30)     NULL,
	DMS_USER_STATUS_CODE       nvarchar(5)     NULL,
	DMS_VIN       nvarchar(35)     NULL,
	LEAD_BRAND_CODE       nvarchar(5)     NULL,
	LEAD_EMP_RESPONSIBLE_DEAL_NAME       nvarchar(81)     NULL,
	LEAD_ENQUIRY_TYPE_CODE       nvarchar(4)     NULL,
	LEAD_FUEL_TYPE_CODE       nvarchar(8)     NULL,
	LEAD_IN_MARKET_DATE       nvarchar(10)     NULL,
	LEAD_LEAD_CATEGORY_CODE       nvarchar(4)     NULL,
	LEAD_LEAD_STATUS_CODE       nvarchar(30)     NULL,
	LEAD_LEAD_STATUS_REASON_CODE       nvarchar(10)     NULL,
	LEAD_MODEL_OF_INTEREST_CODE       nvarchar(5)     NULL,
	LEAD_MODEL_YEAR       nvarchar(4)     NULL,
	LEAD_NEW_USED_INDICATOR       nvarchar(10)     NULL,
	LEAD_ORIGIN_CODE       nvarchar(3)     NULL,
	LEAD_PRE_LAUNCH_MODEL       nvarchar(1)     NULL,
	LEAD_PREF_CONTACT_METHOD       nvarchar(5)     NULL,
	LEAD_SECON_DEALER_CODE       nvarchar(60)     NULL,
	LEAD_VEH_SALE_TYPE_CODE       nvarchar(10)     NULL,
	OBJECT_ID       nvarchar(10)     NULL,
	ROADSIDE_ACTIVE_STATUS_CODE       nvarchar(5)     NULL,
	ROADSIDE_ACTIVITY_DESC       nvarchar(40)     NULL,
	ROADSIDE_COUNTRY_ISO_CODE       nvarchar(3)     NULL,
	ROADSIDE_CUSTOMER_SUMMARY_INC       nvarchar(max)     NULL,
	ROADSIDE_DATA_SOURCE       nvarchar(60)     NULL,
	ROADSIDE_DATE_CALL_ANSWERED       nvarchar(10)     NULL,
	ROADSIDE_DATE_CALL_RECEIVED       nvarchar(10)     NULL,
	ROADSIDE_DATE_JOB_COMPLETED       nvarchar(10)     NULL,
	ROADSIDE_DATE_RESOURCE_ALL       nvarchar(10)     NULL,
	ROADSIDE_DATE_RESOURCE_ARRIVED       nvarchar(10)     NULL,
	ROADSIDE_DATE_SECON_RES_ALL       nvarchar(10)     NULL,
	ROADSIDE_DATE_SECON_RES_ARR       nvarchar(10)     NULL,
	ROADSIDE_DRIVER_EMAIL       nvarchar(241)     NULL,
	ROADSIDE_DRIVER_FIRST_NAME       nvarchar(40)     NULL,
	ROADSIDE_DRIVER_LAST_NAME       nvarchar(40)     NULL,
	ROADSIDE_DRIVER_MOBILE       nvarchar(30)     NULL,
	ROADSIDE_DRIVER_TITLE       nvarchar(30)     NULL,
	ROADSIDE_INCIDENT_CATEGORY       nvarchar(60)     NULL,
	ROADSIDE_INCIDENT_COUNTRY       nvarchar(3)     NULL,
	ROADSIDE_INCIDENT_DATE       nvarchar(10)     NULL,
	ROADSIDE_INCIDENT_ID       nvarchar(20)     NULL,
	ROADSIDE_INCIDENT_SUMMARY       nvarchar(max)     NULL,
	ROADSIDE_INCIDENT_TIME       nvarchar(20)     NULL,
	ROADSIDE_LICENSE_PLATE_REG_NO       nvarchar(15)     NULL,
	ROADSIDE_PROVIDER       nvarchar(60)     NULL,
	ROADSIDE_REPAIRING_SEC_DEAL_CD       nvarchar(60)     NULL,
	ROADSIDE_RESOLUTION_TIME       nvarchar(20)     NULL,
	ROADSIDE_TIME_CALL_ANSWERED       nvarchar(20)     NULL,
	ROADSIDE_TIME_CALL_RECEIVED       nvarchar(20)     NULL,
	ROADSIDE_TIME_JOB_COMPLETED       nvarchar(20)     NULL,
	ROADSIDE_TIME_RESOURCE_ALL       nvarchar(20)     NULL,
	ROADSIDE_TIME_RESOURCE_ARRIVED       nvarchar(20)     NULL,
	ROADSIDE_TIME_SECON_RES_ALL       nvarchar(20)     NULL,
	ROADSIDE_TIME_SECON_RES_ARR       nvarchar(20)     NULL,
	ROADSIDE_VIN       nvarchar(35)     NULL,
	ROADSIDE_WAIT_TIME       nvarchar(20)     NULL,
	VEH_BRAND       nvarchar(10)     NULL,
	VEH_BUILD_DATE       nvarchar(10)     NULL,
	VEH_CHASSIS_NUMBER       nvarchar(30)     NULL,
	VEH_COMMON_ORDER_NUMBER       nvarchar(35)     NULL,
	VEH_COUNTRY_EQUIPMENT_CODE       nvarchar(60)     NULL,
	VEH_CREATING_DEALER       nvarchar(40)     NULL,
	VEH_CURR_PLANNED_DELIVERY_DATE       nvarchar(10)     NULL,
	VEH_CURRENT_PLANNED_BUILD_DATE       nvarchar(10)     NULL,
	VEH_DEA_NAME_LAST_SELLING_DEAL       nvarchar(81)     NULL,
	VEH_DEALER_NAME_OF_SELLING_DEA       nvarchar(81)     NULL,
	VEH_DELIVERED_DATE       nvarchar(10)     NULL,
	VEH_DERIVATIVE       nvarchar(60)     NULL,
	VEH_DRIVER_FULL_NAME       nvarchar(81)     NULL,
	VEH_ENGINE_SIZE       nvarchar(40)     NULL,
	VEH_EXTERIOR_COLOUR_CODE       nvarchar(10)     NULL,
	VEH_EXTERIOR_COLOUR_DESC       nvarchar(40)     NULL,
	VEH_EXTERIOR_COLOUR_SUPPL_CODE       nvarchar(10)     NULL,
	VEH_EXTERIOR_COLOUR_SUPPL_DESC       nvarchar(60)     NULL,
	VEH_FEATURE_CODE       nvarchar(max)     NULL,
	VEH_FINANCE_PROD       nvarchar(40)     NULL,
	VEH_FIRST_RETAIL_SALE       nvarchar(10)     NULL,				-- 15234 - Size increased to 10
	VEH_FUEL_TYPE_CODE       nvarchar(10)     NULL,					-- Task 325 - Size increased to 10 to match XML
	VEH_MODEL       nvarchar(40)     NULL,
	VEH_MODEL_DESC       nvarchar(60)     NULL,
	VEH_MODEL_YEAR       nvarchar(4)     NULL,
	VEH_NUM_OF_OWNERS_RELATIONSHIP       int     NULL,
	VEH_ORIGIN       nvarchar(30)     NULL,
	VEH_OWNERSHIP_STATUS       nvarchar(15)     NULL,
	VEH_OWNERSHIP_STATUS_CODE       nvarchar(5)     NULL,
	VEH_PAYMENT_TYPE       nvarchar(30)     NULL,
	VEH_PREDICTED_REPLACEMENT_DATE       nvarchar(10)     NULL,
	VEH_REACQUIRED_INDICATOR       nvarchar(1)     NULL,
	VEH_REGISTRAT_LICENC_PLATE_NUM       nvarchar(15)     NULL,
	VEH_REGISTRATION_DATE       nvarchar(10)     NULL,
	VEH_SALE_TYPE_DESC		nvarchar(40)		NULL,
	VEH_VIN       nvarchar(35)     NULL,
	VEH_VISTA_CONTRACT_NUMBER       nvarchar(30)     NULL,
	VISTACONTRACT_COMM_TY_SALE_DS       nvarchar(40)     NULL,
	VISTACONTRACT_HANDOVER_DATE       nvarchar(10)     NULL,
	VISTACONTRACT_PREV_VEH_BRAND       nvarchar(20)     NULL,
	VISTACONTRACT_PREV_VEH_MODEL       nvarchar(40)     NULL,
	VISTACONTRACT_SALES_MAN_CD_DES       nvarchar(60)     NULL,
	VISTACONTRACT_SALES_MAN_FULNAM       nvarchar(40)     NULL,
	VISTACONTRACT_SALESMAN_CODE       nvarchar(60)     NULL,
	VISTACONTRACT_SECON_DEALER_CD       nvarchar(60)     NULL,
	VISTACONTRACT_TRADE_IN_MANUFAC       nvarchar(40)     NULL,
	VISTACONTRACT_TRADE_IN_MODEL       nvarchar(40)     NULL,

	VISTACONTRACT_ACTIVITY_CATEGRY		nvarchar(3)		NULL,
	VISTACONTRACT_RETAIL_PRICE			decimal(17)     NULL,

	VEH_APPR_WARNTY_TYPE        nvarchar(100)     NULL,
	VEH_APPR_WARNTY_TYPE_DESC       nvarchar(60)     NULL,
	VISTACONTRACTNAPPRO_RETAIL_WAR       nvarchar(5)     NULL,
	VISTACONTRACTNAPPRO_RETAIL_DES       nvarchar(100)     NULL,
	VISTACONTRACT_EXT_WARR       nvarchar(5)     NULL,
	VISTACONTRACT_EXT_WARR_DESC       nvarchar(40)     NULL,
	ACCT_CONSENT_JAGUAR_FAX       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_FAX       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_CHAT       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_CHAT       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_SMS       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_SMS       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_SMEDIA       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_SMEDIA       nvarchar(60)     NULL,
	ACCT_CONSENT_OVER_CONT_SUP_JAG       nvarchar(60)     NULL,
	ACCT_CONSENT_OVER_CONT_SUP_LR       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTSMR       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTSMR       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTVSM       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTVSM       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTAM       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTAM       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTNAU       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTNAU       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PEVENT       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PEVENT       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PND3P       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PND3P       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTSDWD       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTSDWD       nvarchar(60)     NULL,
	ACCT_CONSENT_JAGUAR_PTPA       nvarchar(60)     NULL,
	ACCT_CONSENT_LAND_ROVER_PTPA       nvarchar(60)     NULL,
	RESPONSE_ID						nvarchar(12)     NULL,
	
	VISTACONTRACT_COMMON_ORDER_NUM	nvarchar(35)	NULL,

	DMS_OTHER_RELATED_SERVICES		nvarchar(max)  NULL,		-- BUG 14122 - 2017-09-06

	VEH_SALE_TYPE_CODE				nvarchar(6),				-- BUG 14344 - 2017-10-30
	VISTACONTRACT_COMM_TY_SALE_CD	nvarchar(6),				-- BUG 14344 - 2017-10-30
	[ISOAlpha2LanguageCode]			varchar(50) NULL,			-- BUG 14677 - 2018-04-26 (ADD DEFAULT LANGUAGE WHEN NECESSARY)

	
	-- CRM 4.1 Changes - BUG 14740 -- 09-07-2017--------------------------------------------------
	LEAD_STATUS_REASON_LEV1_DESC  NVARCHAR(40)  NULL,
	LEAD_STATUS_REASON_LEV1_COD   NVARCHAR(20)  NULL,
	LEAD_STATUS_REASON_LEV2_DESC  NVARCHAR(50)  NULL,
	LEAD_STATUS_REASON_LEV2_COD   NVARCHAR(20)  NULL,
	LEAD_STATUS_REASON_LEV3_DESC  NVARCHAR(30)  NULL,
	LEAD_STATUS_REASON_LEV3_COD   NVARCHAR(20)  NULL,

	JAGDIGITALEVENTSEXP         NVARCHAR(3)  NULL,
	JAGDIGITALINCONTROL         NVARCHAR(3)  NULL,
	JAGDIGITALOWNERVEHCOMM      NVARCHAR(3)  NULL,
	JAGDIGITALPARTNERSSPONSORS  NVARCHAR(3)  NULL,
	JAGDIGITALPRODSERV          NVARCHAR(3)  NULL,
	JAGDIGITALPROMOTIONSOFFERS  NVARCHAR(3)  NULL,
	JAGDIGITALSURVEYSRESEARCH   NVARCHAR(3)  NULL,
	JAGEMAILEVENTSEXP           NVARCHAR(3)  NULL,
	JAGEMAILINCONTROL           NVARCHAR(3)  NULL,
	JAGEMAILOWNERVEHCOMM        NVARCHAR(3)  NULL,
	JAGEMAILPARTNERSSPONSORS    NVARCHAR(3)  NULL,
	JAGEMAILPRODSERV            NVARCHAR(3)  NULL,
	JAGEMAILPROMOTIONSOFFERS    NVARCHAR(3)  NULL,
	JAGEMAILSURVEYSRESEARCH     NVARCHAR(3)  NULL,
	JAGPHONEEVENTSEXP           NVARCHAR(3)  NULL,
	JAGPHONEINCONTROL           NVARCHAR(3)  NULL,
	JAGPHONEOWNERVEHCOMM        NVARCHAR(3)  NULL,
	JAGPHONEPARTNERSSPONSORS    NVARCHAR(3)  NULL,
	JAGPHONEPRODSERV            NVARCHAR(3)  NULL,
	JAGPHONEPROMOTIONSOFFERS    NVARCHAR(3)  NULL,
	JAGPHONESURVEYSRESEARCH     NVARCHAR(3)  NULL,
	JAGPOSTEVENTSEXP            NVARCHAR(3)  NULL,
	JAGPOSTINCONTROL            NVARCHAR(3)  NULL,
	JAGPOSTOWNERVEHCOMM         NVARCHAR(3)  NULL,
	JAGPOSTPARTNERSSPONSORS     NVARCHAR(3)  NULL,
	JAGPOSTPRODSERV             NVARCHAR(3)  NULL,
	JAGPOSTPROMOTIONSOFFERS     NVARCHAR(3)  NULL,
	JAGPOSTSURVEYSRESEARCH      NVARCHAR(3)  NULL,
	JAGSMSEVENTSEXP             NVARCHAR(3)  NULL,
	JAGSMSINCONTROL             NVARCHAR(3)  NULL,
	JAGSMSOWNERVEHCOMM          NVARCHAR(3)  NULL,
	JAGSMSPARTNERSSPONSORS      NVARCHAR(3)  NULL,
	JAGSMSPRODSERV              NVARCHAR(3)  NULL,
	JAGSMSPROMOTIONSOFFERS      NVARCHAR(3)  NULL,
	JAGSMSSURVEYSRESEARCH       NVARCHAR(3)  NULL,
	LRDIGITALEVENTSEXP          NVARCHAR(3)  NULL,
	LRDIGITALINCONTROL          NVARCHAR(3)  NULL,
	LRDIGITALOWNERVEHCOMM       NVARCHAR(3)  NULL,
	LRDIGITALPARTNERSSPONSORS   NVARCHAR(3)  NULL,
	LRDIGITALPRODSERV           NVARCHAR(3)  NULL,
	LRDIGITALPROMOTIONSOFFERS   NVARCHAR(3)  NULL,
	LRDIGITALSURVEYSRESEARCH    NVARCHAR(3)  NULL,
	LREMAILEVENTSEXP            NVARCHAR(3)  NULL,
	LREMAILINCONTROL            NVARCHAR(3)  NULL,
	LREMAILOWNERVEHCOMM         NVARCHAR(3)  NULL,


	LREMAILPARTNERSSPONSORS     NVARCHAR(3)  NULL,
	LREMAILPRODSERV             NVARCHAR(3)  NULL,
	LREMAILPROMOTIONSOFFERS     NVARCHAR(3)  NULL,
	LREMAILSURVEYSRESEARCH      NVARCHAR(3)  NULL,
	LRPHONEEVENTSEXP            NVARCHAR(3)  NULL,
	LRPHONEINCONTROL            NVARCHAR(3)  NULL,
	LRPHONEOWNERVEHCOMM         NVARCHAR(3)  NULL,
	LRPHONEPARTNERSSPONSORS     NVARCHAR(3)  NULL,
	LRPHONEPRODSERV             NVARCHAR(3)  NULL,
	LRPHONEPROMOTIONSOFFERS     NVARCHAR(3)  NULL,
	LRPHONESURVEYSRESEARCH      NVARCHAR(3)  NULL,
	LRPOSTEVENTSEXP             NVARCHAR(3)  NULL,
	LRPOSTINCONTROL             NVARCHAR(3)  NULL,
	LRPOSTOWNERVEHCOMM          NVARCHAR(3)  NULL,
	LRPOSTPARTNERSSPONSORS      NVARCHAR(3)  NULL,
	LRPOSTPRODSERV              NVARCHAR(3)  NULL,
	LRPOSTPROMOTIONSOFFERS      NVARCHAR(3)  NULL,
	LRPOSTSURVEYSRESEARCH       NVARCHAR(3)  NULL,
	LRSMSEVENTSEXP              NVARCHAR(3)  NULL,
	LRSMSINCONTROL              NVARCHAR(3)  NULL,
	LRSMSOWNERVEHCOMM           NVARCHAR(3)  NULL,
	LRSMSPARTNERSSPONSORS       NVARCHAR(3)  NULL,
	LRSMSPRODSERV               NVARCHAR(3)  NULL,
	LRSMSPROMOTIONSOFFERS       NVARCHAR(3)  NULL,
	LRSMSSURVEYSRESEARCH        NVARCHAR(3)  NULL,

	ACCT_NAME_PREFIX_CODE		NVARCHAR(4)  NULL,
	ACCT_NAME_PREFIX			NVARCHAR(40)  NULL,
	
	DMS_REPAIR_ORDER_NUMBER_UNIQUE   nvarchar(35)     NULL,		-- BUG 15234 - Bringing all staging tables in line

	VEH_FUEL_TYPE							nvarchar(40) NULL,	-- BUG 15234 - Pre-existing columns now being included in the CRM staging tables

	CNT_ABTNR									NVARCHAR(4)	 NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_ADDRESS								   NVARCHAR(241) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_DPRTMNT									NVARCHAR(40) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_FIRST_NAME								NVARCHAR(40) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_FNCTN									NVARCHAR(40) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_LAST_NAME								NVARCHAR(40) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_PAFKT									NVARCHAR(4)	 NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_RELTYP									NVARCHAR(6)	 NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CNT_TEL_NUMBER								NVARCHAR(30) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables
	CONTACT_PER_ID								NVARCHAR(10) NULL,  -- BUG 15234 - Pre-existing columns now being included in the CRM staging tables

	ACCT_NAME_CREATING_DEA						NVARCHAR(81) NULL,  -- BUG 15234 - New columns added to CRM
	CNT_MOBILE_PHONE							NVARCHAR(30) NULL,  -- BUG 15234 - New columns added to CRM
	CNT_ACADEMIC_TITLE							NVARCHAR(40) NULL,  -- BUG 15234 - New columns added to CRM
	CNT_ACADEMIC_TITLE_CODE						NVARCHAR(4)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_NAME_PREFIX_CODE						NVARCHAR(4)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_NAME_PREFIX								NVARCHAR(40) NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALOWNERVEHCOMM					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALPARTNERSSPONSORS 				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALPRODSERV						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALPROMOTIONSOFFERS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGDIGITALSURVEYSRESEARCH				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILOWNERVEHCOMM					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILPARTNERSSPONSORS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILPRODSERV						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILPROMOTIONSOFFERS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGEMAILSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEOWNERVEHCOMM 					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEPARTNERSSPONSORS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEPRODSERV						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONEPROMOTIONSOFFERS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPHONESURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTOWNERVEHCOMM						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGPOSTSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSEVENTSEXP							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSINCONTROL							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSOWNERVEHCOMM						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_JAGSMSSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALOWNERVEHCOMM					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALPARTNERSSPONSORS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALPRODSERV						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALPROMOTIONSOFFERS				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRDIGITALSURVEYSRESEARCH				NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILOWNERVEHCOMM 					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LREMAILSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEEVENTSEXP						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEINCONTROL						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEOWNERVEHCOMM						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONEPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPHONESURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTEVENTSEXP							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTINCONTROL							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTOWNERVEHCOMM						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRPOSTSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSEVENTSEXP							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSINCONTROL							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSOWNERVEHCOMM						NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSPARTNERSSPONSORS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSPRODSERV							NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSPROMOTIONSOFFERS					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM
	CNT_LRSMSSURVEYSRESEARCH					NVARCHAR(3)	 NULL,  -- BUG 15234 - New columns added to CRM

	CNT_TITLE									NVARCHAR(30) NULL, -- BUG 15234 - New columns added to CRM
	CNT_TITLE_CODE								NVARCHAR(4)  NULL, -- BUG 15234 - New columns added to CRM
	CNT_PREF_LANGUAGE							NVARCHAR(16) NULL, -- BUG 15234 - New columns added to CRM
	CNT_PREF_LANGUAGE_CODE						NVARCHAR(2)  NULL, -- BUG 15234 - New columns added to CRM
	
	CNT_NON_ACADEMIC_TITLE_CODE					NVARCHAR(4)  NULL,  -- Added with SC00146 version 5.7 (see BUG 16755)
	CNT_NON_ACADEMIC_TITLE						NVARCHAR(80) NULL,	-- Added with SC00146 version 5.7 (see BUG 16755)
	CNT_PREF_LAST_NAME							NVARCHAR(50) NULL,	-- Added with SC00146 version 5.3 (see BUG 15234/16755)
	ACCT_PREF_LAST_NAME							NVARCHAR(50) NULL,	-- Added with SC00146 version 5.3 (see BUG 15234/16755)
	VISTACONTRACT_PREVIOUS_RET_USE				NVARCHAR(4) NULL	-- Added for Task 325

) ON [PRIMARY]