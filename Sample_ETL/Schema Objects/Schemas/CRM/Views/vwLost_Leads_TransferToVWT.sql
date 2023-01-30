CREATE VIEW [CRM].[vwLost_Leads_TransferToVWT]
AS 

/*
	Purpose:	Identify which CRM sourced Lost Leads events have yet to be transferred to VWT
	
	Version		Developer			Date			Comment
	1.0			Martin Riverol		04/08/2014		Created
	1.1			Chris Ross			12/05/2015		BUG 11447: Updated with new column mappings + NULL if 'UNKNOWN' in reg no
															   Include additional columns to populate address.
	1.4			Chris Ross			20/01/2015		BUG 11447: Modify to include the Party Suppression columns for Jaguar and Land Rover
	1.5			Chris Ross			09/02/2016		BUG 11447: Modify to code Country to be UK for Jersey, Guernsey and Isle of Man received codes
	1.6			Eddie Thomas		07/04/2016		BUG 12446: Added ManufacturerPartyID identification via VIN Model matching. SAD VIN's were 
																being coded as 0  
	1.7			Chris Ross			07/07/2016		BUG 12777: Add in new IndustryClassification column based on the ACCT_BP_ROLE field.
	1.12		Chris Ledger		11/01/2017		BUG 13280: Add US Specific Addressing Rules
	1.13		Chris Ledger		05/05/2017		BUG 13896: Exclude records where ACCT_COUNTRY_CODE IS NULL
	1.14		Chris Ledger		10/01/2018		BUG 14261: Modify to code Country to be US for PR received codes
	1.15		Chris Ross			09/07/2018		BUG 14740: Remove old Contact Preferences columns and add in new.
	1.16		Chris Ross			30/10/2018		BUG 15082: Include ACCT_ACCT_TYPE_CODE column.  Set NULL Contact Preferences to Blank. 
	1.17		Chris Ross			12/02/2019		BUG 15234: Add in conditional Org Contact values on appropriate contact columns.
	1.18		Chris Ross			22/11/2019		BUG 16731: Add in Calculated_Salutation and Calculated_Title column.
	1.20		Chris Ledger		11/03/2021		TASK 299: Add in General Enquiry columns.
	1.21		Chris Ledger		19/05/2021		TASK 299: Add in RESPONSE_ID
	1.22		Chris Ledger		16/06/2021		TASK 411: Add Andora to Spain
	1.23		Ben King			10/08/2021      TASK 567: Add Lost Leads
	1.24		Chris Ledger		20/08/2021		TASK 567: Add in DealerCode, update CustomerIdentifier & ManufacturerPartyID, remove General Enquiry columns
	1.25		Chris Ledger		02/09/2021		TASK 595: Add GU & VI to US; BW, MZ, MU & NA to RZ; SK to CZ	
	1.26		Chris Ledger		07/09/2021		TASK 595: Pick up ACCT_COUNTRY_CODE from Sample File	
*/
	WITH CTE_Manfacturers AS		-- Ensures only single manufacturer returned for each row
	(
		SELECT DISTINCT CRM.ID, 
			--MO.ManufacturerPartyID,
			CASE	WHEN CRM.ACCT_ACCT_TYPE = 'Organization' THEN 1													-- V1.20
					ELSE 0 END AS OrgContact
		FROM CRM.Lost_Leads CRM
			--LEFT JOIN [$(SampleDB)].Vehicle.VehicleMatchingStrings	VMS ON CRM.GENERAL_ENQUIRY_VIN_NO LIKE VMS.VehicleMatchingString		-- V1.20	
			--																AND VMS.VehicleMatchingStringTypeID = 1
			--LEFT JOIN [$(SampleDB)].Vehicle.ModelMatching MM ON VMS.VehicleMatchingStringID = MM.VehicleMatchingStringID 
			--LEFT JOIN [$(SampleDB)].Vehicle.Models MO ON MM.ModelID = MO.ModelID 
		WHERE CRM.DateTransferredToVWT IS NULL
	), CTE_Country AS			-- V1.26
	(
		SELECT DISTINCT CRM.AuditItemID, 
			COALESCE(C.ISOAlpha2, CRM.ACCT_COUNTRY_CODE) AS ACCT_COUNTRY_CODE
		FROM CRM.Lost_Leads CRM
			LEFT JOIN [$(AuditDB)].dbo.Files F ON CRM.AuditID = F.AuditID
			LEFT JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON F.FileName LIKE SM.SampleFileNamePrefix + '%' + SM.SampleFileExtension
			LEFT JOIN [$(SampleDB)].dbo.Markets M ON SM.Market = M.Market
			LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON M.CountryID = C.CountryID
	)	
	SELECT 
		AuditID,
		PhysicalRowID,
		CRM.AuditItemID,								-- V1.26
		Converted_ACCT_DATE_OF_BIRTH,
		Converted_ACCT_DATE_ADVISED_OF_DEATH,
		Converted_VEH_REGISTRATION_DATE,
		Converted_VEH_BUILD_DATE,
		Converted_DMS_REPAIR_ORDER_CLOSED_DATE,
		Converted_ROADSIDE_DATE_JOB_COMPLETED,
		Converted_CASE_CASE_SOLVED_DATE,
		Converted_VISTACONTRACT_HANDOVER_DATE,
		Converted_GENERAL_ENQRY_INTERACTION_DATE,		-- V1.20
		Converted_LEAD_CREATION_DATE,					-- V1.23
		Converted_LEAD_IN_MARKET_DATE,					-- V1.23
		Converted_LEAD_CLOSURE_DATE,					-- V1.23
		Converted_LEAD_PREF_DATE_TIME_OF_CONTACT,		-- V1.23		
		CASE	WHEN OrgContact = 0 THEN ACCT_ACCT_ID 
				ELSE '' END AS ACCT_ACCT_ID,										-- V1.19
		COALESCE(Calculated_Title, (CASE	WHEN OrgContact = 0 THEN ACCT_TITLE 
											ELSE CNT_TITLE END)) AS ACCT_TITLE,		-- V1.19, V1.20
		CASE	WHEN OrgContact = 0 THEN ACCT_INITIALS 
				ELSE '' END AS ACCT_INITIALS,										-- V1.19
		CASE	WHEN OrgContact = 0 THEN ACCT_FIRST_NAME 
				ELSE CNT_FIRST_NAME END AS ACCT_FIRST_NAME,							-- V1.19
		CASE	WHEN OrgContact = 0 THEN ACCT_MIDDLE_NAME 
				ELSE '' END AS ACCT_MIDDLE_NAME,									-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(ACCT_LAST_NAME, '') 
				ELSE ISNULL(CNT_LAST_NAME, '') END AS ACCT_LAST_NAME,				-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(ACCT_ADDITIONAL_LAST_NAME, '') 
				ELSE '' END AS ACCT_ADDITIONAL_LAST_NAME,							-- V1.19
		ACCT_GENDER_MALE,
		ACCT_GENDER_FEMALE,
		ACCT_GENDER_UNKNOWN,
		ACCT_DATE_OF_BIRTH,
		ACCT_EMPLOYER_NAME,
		ACCT_NAME_1,
		ACCT_NAME_2,
		--ACCT_CONSENT_JAGUAR_PHONE,					-- V1.10, V1.17
		--ACCT_CONSENT_LR_PHONE,						-- V1.10, V1.17
		--ACCT_CONSENT_JAGUAR_EMAIL,					-- V1.10, V1.17
		--ACCT_CONSENT_LAND_ROVER_EMAIL					-- V1.10, V1.17
		--ACCT_CONSENT_JAGUAR_POST,						-- V1.10, V1.17
		--ACCT_CONSENT_LAND_ROVER_POST,					-- V1.10, V1.17
		ACCT_ROOM_NUMBER,								-- V1.1
		ACCT_BUILDING,									-- V1.1
		ACCT_HOUSE_NO,
--		ACCT_PREFIX_1,
--		ACCT_PREFIX_2,
		ACCT_STREET,
		CASE	WHEN C.ACCT_COUNTRY_CODE = 'US' THEN ''					-- V1.12 NO SubLocality FOR US, V1.25, V1.26
				ELSE ACCT_SUPPLEMENT_1 END AS ACCT_SUPPLEMENT_1,						-- V1.12 ACCT_SUPPLEMENT_1 IS MAPPED TO SubLocality IN VWT
		CASE	WHEN C.ACCT_COUNTRY_CODE = 'US' THEN ''					-- V1.12 NO Locality FOR US, V1.25, V1.26
				ELSE ACCT_SUPPLEMENT_2 END AS ACCT_SUPPLEMENT_2,						-- V1.12 ACCT_SUPPLEMENT_2 IS MAPPED TO Locality IN VWT
		ACCT_SUPPLEMENT_3,
		ACCT_CITY_TOWN,
		ACCT_REGION_STATE,
		COALESCE(NULLIF(ACCT_POSTCODE_ZIP, ''), ACCT_POST_CODE2) AS ACCT_POSTCODE_ZIP,	-- V1.1 Use PO Box postcode if normal postcode is empty
		--CASE	WHEN ACCT_COUNTRY_CODE IN ('IM','JE','GG') THEN 'GB' 
		--		WHEN ACCT_COUNTRY_CODE IN ('GU','PR','VI') THEN 'US'					-- V1.15, V1.25
		--		WHEN ACCT_COUNTRY_CODE IN ('AD') THEN 'ES'								-- V1.21
		--		WHEN ACCT_COUNTRY_CODE IN ('SK') THEN 'CZ'								-- V1.25
		--		ELSE ACCT_COUNTRY_CODE END AS ACCT_COUNTRY_CODE,						-- V1.5
		C.ACCT_COUNTRY_CODE,															-- V1.26
		ACCT_PREF_LANGUAGE_CODE,									-- V1.19  -- V1.20
		ACCT_HOME_EMAIL_ADDR_PRIMARY,								-- V1.1 prev ACCT_HOME_EMAIL_ADDRESS_PRIMARY   -- V1.17  -- V1.20
		ACCT_WORK_PHONE_PRIMARY,									-- V1.17  -- V1.20
		ACCT_HOME_PHONE_NUMBER,									-- V1.20
		ACCT_MOBILE_NUMBER,										-- V1.17  -- V1.20
		VEH_VIN,
		VEH_MODEL_DESC,
		NULLIF(DMS_LICENSE_PLATE_REGISTRATION, 'UNKNOWN') AS DMS_LICENSE_PLATE_REGISTRATION, -- prev VEH_REGISTRATION_LICENCE_PLATE_NUMBER
		VEH_REGISTRATION_DATE,
		VEH_NUM_OF_OWNERS_RELATIONSHIP,			-- V1.1 prev VEH_NUMBER_OF_OWNERS_RELATIONSHIPS
		CASE	WHEN LEN(LEAD_SECON_DEALER_CODE) < 5 THEN NULL  -- Check that there are enough chars to do a substring first		-- V1.24
				WHEN SUBSTRING(LEAD_SECON_DEALER_CODE, 1, 1) = 'J' THEN SUBSTRING(LEAD_SECON_DEALER_CODE, 4, 15)					-- V1.24
				WHEN SUBSTRING(LEAD_SECON_DEALER_CODE, 1, 1) = 'L' THEN SUBSTRING(LEAD_SECON_DEALER_CODE, 5, 15)					-- V1.24
				ELSE NULL END AS DealerCode,																						-- V1.24 LEAD_SECON_DEALER_CODE
		CASE	WHEN C.ACCT_COUNTRY_CODE = 'US' THEN ''		-- V1.12 NO SubStreet FOR US, V1.25, V1.26
				ELSE ACCT_PO_BOX END AS ACCT_PO_BOX,						-- V1.12 ACCT_PO_BOX IS MAPPED TO SubStreet IN VWT
		CASE 	WHEN C.ACCT_COUNTRY_CODE = 'US' THEN ''		-- V1.12 ACCT_BUILDING NOT USED BY US, V1.25, V1.26
				ELSE COALESCE(NULLIF(ACCT_BUILDING, ''), ACCT_SUPPLEMENT_1) END AS BuildingName,	-- V1.1 Because ACCT_SUPPLEMENT_1 holds building name if it can't fit in ACCT_BUILDING
		CASE 	WHEN C.ACCT_COUNTRY_CODE = 'US' THEN COALESCE(NULLIF(ACCT_HOUSE_NUM2, ''), NULLIF(ACCT_SUPPLEMENT_1, ''), ACCT_FLOOR + ' ' + ACCT_ROOM_NUMBER)	-- V1.12 US USES ACCT_HOUSE_NUM2 OR ACCT_SUPPLEMENT_1 OR ACCT_FLOOR + ' ' + ACCT_ROOM_NUMBER, V1.25, V1.26
				ELSE COALESCE(NULLIF(ACCT_ROOM_NUMBER, ''), ACCT_HOUSE_NUM2) END AS RoomOrApartment,										-- V1.12 RoomOrAppartment IS MAPPED TO SubStreetNumber IN VWT
		CASE	WHEN OrgContact = 0 THEN ('CRM_' + ACCT_ACCT_ID) 
				ELSE '' END AS CustomerIdentifier,													-- V1.19
		--ACCT_CONSENT_OVER_CONT_SUP_JAG,															-- V1.4, V1.17 
		--ACCT_CONSENT_OVER_CONT_SUP_LR,															-- V1.4, V1.17 
		--ACCT_CONSENT_JAGUAR_PTSMR,																-- V1.7, V1.17 
		--ACCT_CONSENT_LAND_ROVER_PTSMR,															-- V1.7, V1.17 
		CASE	WHEN OrgContact = 0 THEN ISNULL(LRPOSTSURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_LRPOSTSURVEYSRESEARCH, '') END AS LRPOSTSURVEYSRESEARCH,			-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(JAGPOSTSURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_JAGPOSTSURVEYSRESEARCH, '') END AS JAGPOSTSURVEYSRESEARCH,			-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(LREMAILSURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_LREMAILSURVEYSRESEARCH, '') END AS LREMAILSURVEYSRESEARCH,			-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(JAGEMAILSURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_JAGEMAILSURVEYSRESEARCH, '') END AS JAGEMAILSURVEYSRESEARCH,		-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(LRPHONESURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_LRPHONESURVEYSRESEARCH, '') END AS LRPHONESURVEYSRESEARCH,			-- V1.19
		CASE	WHEN OrgContact = 0 THEN ISNULL(JAGPHONESURVEYSRESEARCH, '')	
				ELSE ISNULL(CNT_JAGPHONESURVEYSRESEARCH, '') END AS JAGPHONESURVEYSRESEARCH,		-- V1.19
		CASE LEAD_BRAND_CODE	WHEN 'JAG' THEN 2													-- V1.24
								WHEN 'LAND' THEN 3													-- V1.24
								ELSE 0 END AS ManufacturerPartyID,									-- V1.24
		CRM.Return_BP_Role_IndClass(ACCT_BP_ROLE) AS IndustryClassification,						-- V1.7 
		ACCT_ACCT_TYPE_CODE,						-- V1.16		
		Calculated_Salutation,						-- V1.18
		LEAD_BRAND,									-- V1.23
		LEAD_BRAND_CODE,							-- V1.23
		LEAD_CREATION_DATE,							-- V1.23
		LEAD_DEALER_LEAD_ID,						-- V1.23
		LEAD_DEALER_NAME,							-- V1.23
		LEAD_DIRECT_LINK_VEH_CONFIGURA,				-- V1.23
		LEAD_EMP_RESPONSIBLE_DEAL_NAME,				-- V1.23
		LEAD_ENQUIRY_TYPE,							-- V1.23
		LEAD_ENQUIRY_TYPE_CODE,						-- V1.23
		LEAD_FUEL_TYPE,								-- V1.23
		LEAD_FUEL_TYPE_CODE,						-- V1.23
		LEAD_IN_MARKET_DATE,						-- V1.23
		LEAD_LEAD_CATEGORY,							-- V1.23
		LEAD_LEAD_CATEGORY_CODE,					-- V1.23
		LEAD_LEAD_ID,								-- V1.23
		LEAD_LEAD_STATUS,							-- V1.23
		LEAD_LEAD_STATUS_CODE,						-- V1.23
		LEAD_STATUS_REASON_LEV1_DESC,				-- V1.23
		LEAD_STATUS_REASON_LEV1_COD,				-- V1.23
		LEAD_LEAD_TRANSACTION_TYPE,					-- V1.23
		LEAD_LEAD_TRANSACTION_TYPE_COD,				-- V1.23
		LEAD_MODEL_DERIVATIVE,						-- V1.23
		LEAD_MODEL_OF_INTEREST,						-- V1.23
		LEAD_MODEL_OF_INTEREST_CODE,				-- V1.23
		LEAD_MODEL_YEAR,							-- V1.23
		LEAD_NEW_USED_INDICATOR,					-- V1.23
		LEAD_ORIGIN,								-- V1.23
		LEAD_ORIGIN_CODE,							-- V1.23
		LEAD_PRE_LAUNCH_MODEL,						-- V1.23
		LEAD_PREF_CONTACT_METHOD,					-- V1.23
		LEAD_PREF_DATE_TIME_OF_CONTACT,				-- V1.23
		LEAD_SCORE,									-- V1.23
		LEAD_SECON_DEALER_CODE,						-- V1.23
		LEAD_VEH_SALE_TYPE,							-- V1.23
		LEAD_VEH_SALE_TYPE_CODE,					-- V1.23
		LEAD_STATUS_REASON_LEV2_COD,				-- V1.23
		LEAD_STATUS_REASON_LEV3_COD,				-- V1.23
		LEAD_STATUS_REASON_LEV2_DESC,				-- V1.23
		LEAD_STATUS_REASON_LEV3_DESC,				-- V1.23
		LEAD_CAMPAIGN_DESC,							-- V1.23
		LEAD_CURRENT_MAKE,							-- V1.23
		LEAD_CURRENT_MODEL,							-- V1.23
		LEAD_OWNERSHIP_TYPE,						-- V1.23
		LEAD_QUALIFY_STATUS,						-- V1.23
		LEAD_CLOSURE_DATE							-- V1.23
	FROM CRM.Lost_Leads CRM
		LEFT JOIN CTE_Manfacturers M ON M.ID = CRM.ID								-- V1.6
		LEFT JOIN CTE_Country C ON CRM.AuditItemID = C.AuditItemID					-- V1.26
	WHERE CRM.DateTransferredToVWT IS NULL
		AND CRM.ACCT_COUNTRY_CODE IS NOT NULL;										-- V1.13



GO