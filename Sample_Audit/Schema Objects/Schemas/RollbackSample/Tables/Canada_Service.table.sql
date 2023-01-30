﻿CREATE TABLE RollbackSample.Canada_Service
(
	[AuditID] [dbo].[AuditID] NOT NULL,

	[ID] [int]  NOT NULL,
	[PhysicalRowID] [int] NULL,
	[DateTransferredToVWT] [datetime2](7) NULL, 
	[FilteredFlag]			CHAR(1),
	
	[DEALER_ID]				NVARCHAR(200) NULL,
	[RO_NUM]				NVARCHAR(200) NULL,
	[RO_CLOSE_DATE]			NVARCHAR(200) NULL,
	[RO_OPEN_DATE]			NVARCHAR(200) NULL,
	[CUST_CONTACT_ID]		NVARCHAR(200) NULL,
	[CUST_FIRST_NAME]		NVARCHAR(200) NULL,
	[CUST_MIDDLE_NAME]		NVARCHAR(200) NULL,
	[CUST_LAST_NAME]		NVARCHAR(200) NULL,
	[CUST_SALUTATION]		NVARCHAR(200) NULL,
	[CUST_SUFFIX]			NVARCHAR(200) NULL,
	[CUST_FULL_NAME]		NVARCHAR(200) NULL,
	[CUST_TITLE]			NVARCHAR(200) NULL,
	[CUST_BUSINESS_PERSON_FLAG]     NVARCHAR(200) NULL,
	[CUST_COMPANY_NAME]     NVARCHAR(200) NULL,
	[CUST_DEPARTMENT]		NVARCHAR(200) NULL,
	[CUST_ADDRESS]			NVARCHAR(200) NULL,
	[CUST_DISTRICT]			NVARCHAR(200) NULL,
	[CUST_CITY]				NVARCHAR(200) NULL,
	[CUST_REGION]			NVARCHAR(200) NULL,
	[CUST_POSTAL_CODE]		NVARCHAR(200) NULL,
	[CUST_COUNTRY]			NVARCHAR(200) NULL,
	[CUST_HOME_PH_NUMBER]   NVARCHAR(200) NULL,
	[CUST_HOME_PH_EXTENSION]     NVARCHAR(200) NULL,
	[CUST_BUS_PH_COUNTRY_CODE]     NVARCHAR(200) NULL,
	[CUST_BUS_PH_NUMBER]     NVARCHAR(200) NULL,
	[CUST_BUS_PH_EXTENSION]     NVARCHAR(200) NULL,
	[CUST_BUS_PH_COUNTRY_CODE2]     NVARCHAR(200) NULL,
	[CUST_HOME_EMAIL]     NVARCHAR(200) NULL,
	[CUST_BUS_EMAIL]		NVARCHAR(200) NULL,
	[CUST_BIRTH_DATE]     NVARCHAR(200) NULL,
	[CUST_ALLOW_SOLICIT]     NVARCHAR(200) NULL,
	[CUST_ALLOW_PHONE_SOLICIT]     NVARCHAR(200) NULL,
	[CUST_ALLOW_EMAIL_SOLICIT]     NVARCHAR(200) NULL,
	[CUST_ALLOW_MAIL_SOLICIT]     NVARCHAR(200) NULL,
	[ODOMETER_IN]     NVARCHAR(200) NULL,
	[ODOMETER_OUT]     NVARCHAR(200) NULL,
	[VEHICLE_PICKUP_DATE]     NVARCHAR(200) NULL,
	[APPOINTMENT_FLAG]     NVARCHAR(200) NULL,
	[DEPARTMENT]     NVARCHAR(200) NULL,
	[EXT_SVC_CONTRACT_NAMES]     NVARCHAR(200) NULL,
	[PAYMENT_METHODS]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_PARTS_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_LABOR_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_SUBLET_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_GOG_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_TTL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_PARTS_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_LABOR_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_SUBLET_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_GOG_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_TTL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_CUSTOMER_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_PARTS_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_LABOR_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_SUBLET_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_GOG_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_TTL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_PARTS_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_LABOR_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_SUBLET_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_GOG_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_TTL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_WARRANTY_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_PARTS_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_LABOR_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_SUBLET_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_GOG_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_TTL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_PARTS_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_LABOR_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_SUBLET_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_GOG_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_TTL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_INTERNAL_COST]     NVARCHAR(200) NULL,
	[TOTAL_PARTS_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_LABOR_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_SUBLET_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_GOG_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_TTL_MISC_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_RO_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_TAX_PRICE]     NVARCHAR(200) NULL,
	[TOTAL_PARTS_COST]     NVARCHAR(200) NULL,
	[TOTAL_LABOR_COST]     NVARCHAR(200) NULL,
	[TOTAL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_SUBLET_COST]     NVARCHAR(200) NULL,
	[TOTAL_GOG_COST]     NVARCHAR(200) NULL,
	[TOTAL_TTL_MISC_COST]     NVARCHAR(200) NULL,
	[TOTAL_RO_COST]     NVARCHAR(200) NULL,
	[TOTAL_ACTUAL_LABOR_HOURS]     NVARCHAR(200) NULL,
	[TOTAL_BILLED_LABOR_HOURS]     NVARCHAR(200) NULL,
	[VEH_VIN]     NVARCHAR(200) NULL,
	[VEH_MODEL_YEAR]     NVARCHAR(200) NULL,
	[VEH_MAKE]     NVARCHAR(200) NULL,
	[VEH_MODEL]     NVARCHAR(200) NULL,
	[VEH_TRANS_TYPE]     NVARCHAR(200) NULL,
	[VEH_EXT_COLOR_DESCRIPTION]     NVARCHAR(200) NULL,
	[VEH_REG_LICENSE_PLATE_NUMBER]     NVARCHAR(200) NULL,
	[OPERATIONS]       NVARCHAR(MAX) NULL,
	[TECH_COMMENT]     NVARCHAR(MAX) NULL,
	[CUST_COMMENT]     NVARCHAR(MAX) NULL,
	[SERVICE_ADVISOR_CONTACT_ID]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_FIRST_NAME]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_MIDDLE_NAME]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_LAST_NAME]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_SALUTATION]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_SUFFIX]     NVARCHAR(200) NULL,
	[SERVICE_ADVISOR_FULL_NAME]     NVARCHAR(200) NULL,
	[LANGUAGE]						  NVARCHAR(200) NULL,

	
	TECHNICIAN_CONTACT_ID			NVARCHAR(200) NULL,			-- Extracted from OPERATIONS column
	TECHNICIAN_FULL_NAME			NVARCHAR(200) NULL,			-- Extracted from OPERATIONS column
	OPERATION_PAY_TYPE				NVARCHAR(200) NULL,			-- Extracted from OPERATIONS column - 14-03-2017
	
	[Converted_RO_CLOSE_DATE] [datetime2](7) NULL,
	[Converted_CUST_BIRTH_DATE] [datetime2](7) NULL,
	[ManufacturerPartyID] [int] NULL,
	[SampleSupplierPartyID] [int] NULL,
	[CountryID] [smallint] NULL,
	[EventTypeID] [smallint] NULL,
	[LanguageID] [smallint] NULL,
	[DealerCodeOriginatorPartyID] [int] NULL,
	[SetNameCapitalisation] [bit] NULL,
	[SampleTriggeredSelectionReqID]   INT NULL,
	[CustomerIdentifierUsable] BIT NULL,

	[PDI_Flag] VARCHAR(1) NULL					-- 06-09-2017 - BUG 14122
);

