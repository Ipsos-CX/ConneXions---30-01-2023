CREATE VIEW [Canada].[vwService_LoadtoVWT]
AS 
	

/*
	Purpose:	Return the Canada Service events which have yet to be transferred to VWT
	
	Version		Developer			Date			Comment
	1.0			Chris Ross			16/04/2017		Created
	1.1			Chris Ross			06/09/2017		BUG14122 - Add in PDI_Flag


*/	
	
SELECT [AuditID]
      ,[PhysicalRowID]
      ,[DEALER_ID]
      ,[RO_NUM]
      ,[RO_CLOSE_DATE]
      ,[RO_OPEN_DATE]
      ,[CUST_CONTACT_ID]
      ,[CUST_FIRST_NAME]
      ,[CUST_MIDDLE_NAME]
      ,[CUST_LAST_NAME]
      ,[CUST_SALUTATION]
      ,[CUST_SUFFIX]
      ,[CUST_FULL_NAME]
      ,[CUST_TITLE]
      ,[CUST_BUSINESS_PERSON_FLAG]
      ,[CUST_COMPANY_NAME]
      ,[CUST_DEPARTMENT]
      ,[CUST_ADDRESS]
      ,[CUST_DISTRICT]
      ,[CUST_CITY]
      ,[CUST_REGION]
      ,[CUST_POSTAL_CODE]
      ,[CUST_COUNTRY]
      ,[CUST_HOME_PH_NUMBER]
      ,[CUST_HOME_PH_EXTENSION]
      ,[CUST_BUS_PH_COUNTRY_CODE]
      ,[CUST_BUS_PH_NUMBER]
      ,[CUST_BUS_PH_EXTENSION]
      ,[CUST_BUS_PH_COUNTRY_CODE2]
      ,[CUST_HOME_EMAIL]
      ,[CUST_BUS_EMAIL]
      ,[CUST_BIRTH_DATE]
      ,[CUST_ALLOW_SOLICIT]
      ,[CUST_ALLOW_PHONE_SOLICIT]
      ,[CUST_ALLOW_EMAIL_SOLICIT]
      ,[CUST_ALLOW_MAIL_SOLICIT]
      ,[ODOMETER_IN]
      ,[ODOMETER_OUT]
      ,[VEHICLE_PICKUP_DATE]
      ,[APPOINTMENT_FLAG]
      ,[DEPARTMENT]
      ,[EXT_SVC_CONTRACT_NAMES]
      ,[PAYMENT_METHODS]
      ,[TOTAL_CUSTOMER_PARTS_PRICE]
      ,[TOTAL_CUSTOMER_LABOR_PRICE]
      ,[TOTAL_CUSTOMER_MISC_PRICE]
      ,[TOTAL_CUSTOMER_SUBLET_PRICE]
      ,[TOTAL_CUSTOMER_GOG_PRICE]
      ,[TOTAL_CUSTOMER_TTL_MISC_PRICE]
      ,[TOTAL_CUSTOMER_PRICE]
      ,[TOTAL_CUSTOMER_PARTS_COST]
      ,[TOTAL_CUSTOMER_LABOR_COST]
      ,[TOTAL_CUSTOMER_MISC_COST]
      ,[TOTAL_CUSTOMER_SUBLET_COST]
      ,[TOTAL_CUSTOMER_GOG_COST]
      ,[TOTAL_CUSTOMER_TTL_MISC_COST]
      ,[TOTAL_CUSTOMER_COST]
      ,[TOTAL_WARRANTY_PARTS_PRICE]
      ,[TOTAL_WARRANTY_LABOR_PRICE]
      ,[TOTAL_WARRANTY_MISC_PRICE]
      ,[TOTAL_WARRANTY_SUBLET_PRICE]
      ,[TOTAL_WARRANTY_GOG_PRICE]
      ,[TOTAL_WARRANTY_TTL_MISC_PRICE]
      ,[TOTAL_WARRANTY_PRICE]
      ,[TOTAL_WARRANTY_PARTS_COST]
      ,[TOTAL_WARRANTY_LABOR_COST]
      ,[TOTAL_WARRANTY_MISC_COST]
      ,[TOTAL_WARRANTY_SUBLET_COST]
      ,[TOTAL_WARRANTY_GOG_COST]
      ,[TOTAL_WARRANTY_TTL_MISC_COST]
      ,[TOTAL_WARRANTY_COST]
      ,[TOTAL_INTERNAL_PARTS_PRICE]
      ,[TOTAL_INTERNAL_LABOR_PRICE]
      ,[TOTAL_INTERNAL_MISC_PRICE]
      ,[TOTAL_INTERNAL_SUBLET_PRICE]
      ,[TOTAL_INTERNAL_GOG_PRICE]
      ,[TOTAL_INTERNAL_TTL_MISC_PRICE]
      ,[TOTAL_INTERNAL_PRICE]
      ,[TOTAL_INTERNAL_PARTS_COST]
      ,[TOTAL_INTERNAL_LABOR_COST]
      ,[TOTAL_INTERNAL_MISC_COST]
      ,[TOTAL_INTERNAL_SUBLET_COST]
      ,[TOTAL_INTERNAL_GOG_COST]
      ,[TOTAL_INTERNAL_TTL_MISC_COST]
      ,[TOTAL_INTERNAL_COST]
      ,[TOTAL_PARTS_PRICE]
      ,[TOTAL_LABOR_PRICE]
      ,[TOTAL_MISC_PRICE]
      ,[TOTAL_SUBLET_PRICE]
      ,[TOTAL_GOG_PRICE]
      ,[TOTAL_TTL_MISC_PRICE]
      ,[TOTAL_RO_PRICE]
      ,[TOTAL_TAX_PRICE]
      ,[TOTAL_PARTS_COST]
      ,[TOTAL_LABOR_COST]
      ,[TOTAL_MISC_COST]
      ,[TOTAL_SUBLET_COST]
      ,[TOTAL_GOG_COST]
      ,[TOTAL_TTL_MISC_COST]
      ,[TOTAL_RO_COST]
      ,[TOTAL_ACTUAL_LABOR_HOURS]
      ,[TOTAL_BILLED_LABOR_HOURS]
      ,[VEH_VIN]
      ,[VEH_MODEL_YEAR]
      ,[VEH_MAKE]
      ,[VEH_MODEL]
      ,[VEH_TRANS_TYPE]
      ,[VEH_EXT_COLOR_DESCRIPTION]
      ,[VEH_REG_LICENSE_PLATE_NUMBER]
      ,[OPERATIONS]
      ,[TECH_COMMENT]
      ,[CUST_COMMENT]
      ,[SERVICE_ADVISOR_CONTACT_ID]
      ,[SERVICE_ADVISOR_FIRST_NAME]
      ,[SERVICE_ADVISOR_MIDDLE_NAME]
      ,[SERVICE_ADVISOR_LAST_NAME]
      ,[SERVICE_ADVISOR_SALUTATION]
      ,[SERVICE_ADVISOR_SUFFIX]
      ,[SERVICE_ADVISOR_FULL_NAME]
      ,[TECHNICIAN_CONTACT_ID]
      ,[TECHNICIAN_FULL_NAME]
      ,[OPERATION_PAY_TYPE]
      ,[Converted_RO_CLOSE_DATE]
      ,[Converted_CUST_BIRTH_DATE]
      ,[ManufacturerPartyID]
      ,[SampleSupplierPartyID]
      ,[CountryID]
      ,[EventTypeID]
      ,[LanguageID]
      ,[DealerCodeOriginatorPartyID]
      ,[SetNameCapitalisation]
      ,[SampleTriggeredSelectionReqID]
      ,[CustomerIdentifierUsable]
      ,[PDI_Flag]							-- 06-09-2017 - BUG 14122
FROM Canada.Service
WHERE DateTransferredToVWT IS NULL 
AND ISNULL(FilteredFlag , 'N') <> 'Y'