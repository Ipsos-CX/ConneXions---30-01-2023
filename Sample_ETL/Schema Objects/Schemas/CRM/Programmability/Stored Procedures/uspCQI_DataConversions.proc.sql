CREATE PROCEDURE   [CRM].[uspCQI_DataConversions]

@AuditID BIGINT,					-- V1.7
@SampleFileName  NVARCHAR(100)

AS

/*
		Purpose:	Perform any required data conversions, etc, before loading to VWT.
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ledger		05/05/2021		Created from uspVISTA_DataConversions
LIVE	1.1			Eddie Thomas		26/04/2018		BUG 14677: Iberia Set Up – SV-CRM (Feed Change from Vista to SV-CRM). Ensuring language is populated
LIVE	1.2			Chris Ross			19/11/2019		BUG 16731: Add in additonal Salutation and Title calculation code (used for Germany/Czech/Austria markets).
																   Also, modify convert code to filter those records which haven't yet been loaded to VWT.
LIVE	1.3			Chris Ledger		10/01/2020		BUG 15372: Fix Hard coded references to databases
LIVE	1.4			Chris Ledger		05/05/2021		TASK 411: Copied from uspVISTA_DataConversion
LIVE	1.5			Chris Ledger		16/06/2021		TASK 411: Add Andora to Spain
LIVE	1.6			Chris Ledger		24/08/2021		TASK 502: Change to CQI and add date conversion of DATEOFCONSENT and loading of permission fields
LIVE	1.7			Chris Ledger		27/01/2022		TASK 502: Only allow YA2 for Italy Only allow YA2 for Italy and use @AuditID to filter updating of permission fields
LIVE	1.8			Chris Ledger		03/08/2022		TASK 977: Add Guadeloupe, Monaco, Martinique & Reunion to France
*/

SET NOCOUNT ON


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	---------------------------------------------------------------------------------------------------
	-- V1.7 GET COUNTRYCODE FROM AUDITID
	---------------------------------------------------------------------------------------------------
	DECLARE @CountryCode NVARCHAR(2)

	SELECT @CountryCode = C.ISOAlpha2
	FROM [$(AuditDB)].dbo.Files F
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON F.FileName LIKE SM.SampleFileNamePrefix + '%'
		INNER JOIN [$(SampleDB)].dbo.Markets M ON SM.Market = M.Market
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON M.CountryID = C.CountryID
	WHERE F.AuditID = @AuditID
		AND SM.SampleLoadActive = 1
	GROUP BY C.ISOAlpha2
	---------------------------------------------------------------------------------------------------


	----------------------------------------------------------------------------------------------------
	-- V1.4 Set the EventTypeID 
	----------------------------------------------------------------------------------------------------
	;WITH RecordsToUpdate (ID, CountryCode, Country, CountryID) AS
	(
		--Add In CountryID
		SELECT C.ID, 
			C.ACCT_COUNTRY_CODE AS CountryCode, 
			CN.Country, 
			CN.CountryID
		FROM CRM.CQI C
			INNER JOIN [$(AuditDB)].dbo.Files F ON C.AuditID = F.AuditID		
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries	CN ON CASE	WHEN C.ACCT_COUNTRY_CODE IN ('IM','JE','GG') THEN 'GB' 
																			WHEN C.ACCT_COUNTRY_CODE IN ('PR') THEN 'US'
																			WHEN C.ACCT_COUNTRY_CODE IN ('AD') THEN 'ES'					-- V1.5
																			WHEN C.ACCT_COUNTRY_CODE IN ('GP','MC','MQ','RE') THEN 'FR'		-- V1.8
																			ELSE C.ACCT_COUNTRY_CODE END = CN.ISOAlpha2
		WHERE F.FileName = @SampleFileName									
	)
	--Retrieve Metadata values for each event in the table
	SELECT DISTINCT 
		RU.*, 
		MD.EventTypeID
	INTO #Completed							
	FROM RecordsToUpdate RU 
		INNER JOIN (	SELECT DISTINCT ET.EventTypeID,
							M.CountryID
						FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata	M
							INNER JOIN [$(SampleDB)].[Event].EventTypes ET ON ET.EventType = M.Questionnaire
							INNER JOIN [$(SampleDB)].ContactMechanism.Countries	CN ON CN.CountryID = M.CountryID
						WHERE M.SampleLoadActive = 1 
							AND @SampleFileName LIKE SampleFileNamePrefix + '%') MD ON RU.CountryID = MD.CountryID
							
							
	--Populate the meta data fields for each record
	UPDATE C
	SET	EventTypeID	= CN.EventTypeID
	FROM CRM.CQI C
		INNER JOIN #Completed CN ON C.ID = CN.ID	
	----------------------------------------------------------------------------------------------------


	UPDATE C
	SET Converted_VISTACONTRACT_HANDOVER_DATE = NULLIF(VISTACONTRACT_HANDOVER_DATE, '0000-00-00'),
		Converted_CASE_CASE_SOLVED_DATE = NULLIF(CASE_CASE_SOLVED_DATE, '0000-00-00'),
		Converted_ROADSIDE_DATE_JOB_COMPLETED = NULLIF(ROADSIDE_DATE_JOB_COMPLETED, '0000-00-00'),
		Converted_DMS_REPAIR_ORDER_CLOSED_DATE = NULLIF(DMS_REPAIR_ORDER_CLOSED_DATE, '0000-00-00'),
		Converted_VEH_BUILD_DATE = NULLIF(VEH_BUILD_DATE, '0000-00-00'),
		Converted_VEH_REGISTRATION_DATE = NULLIF(VEH_REGISTRATION_DATE,  '0000-00-00'),
		Converted_ACCT_DATE_ADVISED_OF_DEATH = NULLIF(ACCT_DATE_ADVISED_OF_DEATH, '0000-00-00'),
		Converted_ACCT_DATE_OF_BIRTH = NULLIF(ACCT_DATE_OF_BIRTH, '0000-00-00'),
		ISOAlpha2LanguageCode = ACCT_PREF_LANGUAGE_CODE  -- V1.1
	FROM CRM.CQI C
	WHERE C.DateTransferredToVWT IS NULL	
		AND	C.ACCT_COUNTRY_CODE IS NOT NULL	-- V1.2

	
	-- V1.1	
	UPDATE C
	SET ISOAlpha2LanguageCode = COALESCE(ACCT_PREF_LANGUAGE_CODE, LG.ISOAlpha2)
	FROM CRM.CQI C
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries CN ON C.ACCT_COUNTRY_CODE = CN.ISOAlpha2 
		INNER JOIN [$(SampleDB)].dbo.Languages LG ON CN.DefaultLanguageID = LG.LanguageID
	WHERE C.DateTransferredToVWT IS NULL	
		AND C.ACCT_COUNTRY_CODE IS NOT NULL


	---------------------------------------------------------------------------------------------------
	--- Update CQI_ACCT_MKT_PERM_ITEM.DATEOFCONSENT												-- V1.6
	---------------------------------------------------------------------------------------------------
	UPDATE AMPI
	SET AMPI.Converted_DATEOFCONSENT = NULLIF(AMPI.DATEOFCONSENT, '0000-00-00')
	FROM CRM.CQI C	
		INNER JOIN CRM.CQI_ACCT_MKT_PERM AMP ON C.AuditID = AMP.AuditID
														AND C.item_Id = AMP.item_Id
		INNER JOIN CRM.CQI_ACCT_MKT_PERM_ITEM AMPI ON C.AuditID = AMPI.AuditID
														AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
	WHERE C.AuditID = @AuditID																	-- V1.7


	---------------------------------------------------------------------------------------------------
	--- Update CQI_ACCT_MKT_PERM_ITEM.DATEOFCONSENT												-- V1.6
	---------------------------------------------------------------------------------------------------
	UPDATE CMPI
	SET CMPI.Converted_DATEOFCONSENT = NULLIF(CMPI.DATEOFCONSENT, '0000-00-00')
	FROM CRM.CQI C	
		INNER JOIN CRM.CQI_CNT_MKT_PERM CMP ON C.AuditID = CMP.AuditID
															AND C.item_Id = CMP.item_Id
		INNER JOIN CRM.CQI_CNT_MKT_PERM_ITEM CMPI ON C.AuditID = CMPI.AuditID
															AND CMP.CNT_MKT_PERM_Id = CMPI.CNT_MKT_PERM_Id
	WHERE C.AuditID = @AuditID																	-- V1.7


	---------------------------------------------------------------------------------------------------
	--- Update Personal Permission Fields														-- V1.6
	---------------------------------------------------------------------------------------------------
	;WITH CTE_PIVOT AS
	(
		SELECT ID,
			AuditID,
			AuditItemID,
			item_ID,
			JAGPHONESURVEYSRESEARCH,
			LRPHONESURVEYSRESEARCH,
			JAGEMAILSURVEYSRESEARCH,
			LREMAILSURVEYSRESEARCH,
			JAGPOSTSURVEYSRESEARCH,
			LRPOSTSURVEYSRESEARCH,
			JAGSMSSURVEYSRESEARCH,
			LRSMSSURVEYSRESEARCH,
			JAGDIGITALSURVEYSRESEARCH,
			LRDIGITALSURVEYSRESEARCH,
			CUSTOMERSATISFACTIONSURVEY
		FROM
		(
			SELECT C.ID,
				C.AuditID,
				C.AuditItemID,
				C.item_Id,
				AMPI.ACCT_MKT_PERM_Id,
				CASE AMPI.COMMCHANNEL	WHEN 'Y06' THEN 'JAGPHONESURVEYSRESEARCH'
										WHEN 'Y16' THEN 'LRPHONESURVEYSRESEARCH'
										WHEN 'Y26' THEN 'JAGEMAILSURVEYSRESEARCH'
										WHEN 'Y36' THEN 'LREMAILSURVEYSRESEARCH'
										WHEN 'Y46' THEN 'JAGPOSTSURVEYSRESEARCH'
										WHEN 'Y56' THEN 'LRPOSTSURVEYSRESEARCH'
										WHEN 'Y66' THEN 'JAGSMSSURVEYSRESEARCH'
										WHEN 'Y76' THEN 'LRSMSSURVEYSRESEARCH'
										WHEN 'Y86' THEN 'JAGDIGITALSURVEYSRESEARCH'
										WHEN 'Y96' THEN 'LRDIGITALSURVEYSRESEARCH'
										WHEN 'YA2' THEN 'CUSTOMERSATISFACTIONSURVEY'										
										ELSE NULL END AS Field,
				AMPI.CONSENT
			FROM CRM.CQI C
				INNER JOIN CRM.CQI_ACCT_MKT_PERM AMP ON C.AuditID = AMP.AuditID
																	AND C.item_Id = AMP.item_Id
				LEFT JOIN CRM.CQI_ACCT_MKT_PERM_ITEM AMPI ON C.AuditID = AMPI.AuditID
																	AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
			WHERE C.AuditID = @AuditID																									-- V1.7
				AND ((@CountryCode = 'IT' AND AMPI.COMMCHANNEL = 'YA2')																	-- V1.7
					OR (@CountryCode <> 'IT' AND AMPI.COMMCHANNEL IN ('Y06','Y16','Y26','Y36','Y46','Y56','Y66','Y76','Y86','Y96')))	-- V1.7
		) D
		PIVOT
		(
			MAX(CONSENT)
			FOR Field IN (JAGPHONESURVEYSRESEARCH, LRPHONESURVEYSRESEARCH, JAGEMAILSURVEYSRESEARCH, LREMAILSURVEYSRESEARCH, JAGPOSTSURVEYSRESEARCH, LRPOSTSURVEYSRESEARCH, JAGSMSSURVEYSRESEARCH, LRSMSSURVEYSRESEARCH, JAGDIGITALSURVEYSRESEARCH, LRDIGITALSURVEYSRESEARCH, CUSTOMERSATISFACTIONSURVEY)
		) P
	)
	UPDATE C
	SET C.JAGPHONESURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGPHONESURVEYSRESEARCH END,
		C.LRPHONESURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRPHONESURVEYSRESEARCH END,
		C.JAGEMAILSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGEMAILSURVEYSRESEARCH END,
		C.LREMAILSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LREMAILSURVEYSRESEARCH END,
		C.JAGPOSTSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGPOSTSURVEYSRESEARCH END,
		C.LRPOSTSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRPOSTSURVEYSRESEARCH END,
		C.JAGSMSSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGSMSSURVEYSRESEARCH END,
		C.LRSMSSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
										ELSE P.LRSMSSURVEYSRESEARCH END,
		C.JAGDIGITALSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
												ELSE P.JAGDIGITALSURVEYSRESEARCH END,
		C.LRDIGITALSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRDIGITALSURVEYSRESEARCH END
	FROM CRM.CQI C
		INNER JOIN CTE_PIVOT P ON C.AuditID = P.AuditID
									AND C.AuditItemID = P.AuditItemID
									AND C.item_Id = P.item_Id 
	WHERE C.AuditID = @AuditID																	-- V1.7


	---------------------------------------------------------------------------------------------------
	--- Update Company Permission Fields														-- V1.6
	---------------------------------------------------------------------------------------------------
	;WITH CTE_PIVOT AS
	(
		SELECT ID,
			AuditID,
			AuditItemID,
			item_ID,
			CNT_JAGPHONESURVEYSRESEARCH,
			CNT_LRPHONESURVEYSRESEARCH,
			CNT_JAGEMAILSURVEYSRESEARCH,
			CNT_LREMAILSURVEYSRESEARCH,
			CNT_JAGPOSTSURVEYSRESEARCH,
			CNT_LRPOSTSURVEYSRESEARCH,
			CNT_JAGSMSSURVEYSRESEARCH,
			CNT_LRSMSSURVEYSRESEARCH,
			CNT_JAGDIGITALSURVEYSRESEARCH,
			CNT_LRDIGITALSURVEYSRESEARCH,
			CNT_CUSTOMERSATISFACTIONSURVEY
		FROM
		(
			SELECT C.ID,
				C.AuditID,
				C.AuditItemID,
				C.item_Id,
				CMPI.CNT_MKT_PERM_Id,
				CASE CMPI.COMMCHANNEL	WHEN 'Y06' THEN 'CNT_JAGPHONESURVEYSRESEARCH'
										WHEN 'Y16' THEN 'CNT_LRPHONESURVEYSRESEARCH'
										WHEN 'Y26' THEN 'CNT_JAGEMAILSURVEYSRESEARCH'
										WHEN 'Y36' THEN 'CNT_LREMAILSURVEYSRESEARCH'
										WHEN 'Y46' THEN 'CNT_JAGPOSTSURVEYSRESEARCH'
										WHEN 'Y56' THEN 'CNT_LRPOSTSURVEYSRESEARCH'
										WHEN 'Y66' THEN 'CNT_JAGSMSSURVEYSRESEARCH'
										WHEN 'Y76' THEN 'CNT_LRSMSSURVEYSRESEARCH'
										WHEN 'Y86' THEN 'CNT_JAGDIGITALSURVEYSRESEARCH'
										WHEN 'Y96' THEN 'CNT_LRDIGITALSURVEYSRESEARCH'
										WHEN 'YA2' THEN 'CNT_CUSTOMERSATISFACTIONSURVEY'
										ELSE NULL END AS Field,
				CMPI.CONSENT
			FROM CRM.CQI C
			INNER JOIN CRM.CQI_CNT_MKT_PERM CMP ON C.AuditID = CMP.AuditID
																AND C.item_Id = CMP.item_Id
			LEFT JOIN CRM.CQI_CNT_MKT_PERM_ITEM CMPI ON C.AuditID = CMPI.AuditID
																AND CMP.CNT_MKT_PERM_Id = CMPI.CNT_MKT_PERM_Id
			WHERE C.AuditID = @AuditID																									-- V1.7
				AND ((@CountryCode = 'IT' AND CMPI.COMMCHANNEL = 'YA2')																	-- V1.7
					OR (@CountryCode <> 'IT' AND CMPI.COMMCHANNEL IN ('Y06','Y16','Y26','Y36','Y46','Y56','Y66','Y76','Y86','Y96')))	-- V1.7
		) D
		PIVOT
		(
		  MAX(CONSENT)
		  FOR Field IN (CNT_JAGPHONESURVEYSRESEARCH, CNT_LRPHONESURVEYSRESEARCH, CNT_JAGEMAILSURVEYSRESEARCH, CNT_LREMAILSURVEYSRESEARCH, CNT_JAGPOSTSURVEYSRESEARCH, CNT_LRPOSTSURVEYSRESEARCH, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRSMSSURVEYSRESEARCH,	CNT_JAGDIGITALSURVEYSRESEARCH, CNT_LRDIGITALSURVEYSRESEARCH, CNT_CUSTOMERSATISFACTIONSURVEY)
		) P
	)
	UPDATE C
	SET C.CNT_JAGPHONESURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGPHONESURVEYSRESEARCH END,
		C.CNT_LRPHONESURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRPHONESURVEYSRESEARCH END,
		C.CNT_JAGEMAILSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGEMAILSURVEYSRESEARCH END,
		C.CNT_LREMAILSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LREMAILSURVEYSRESEARCH END,
		C.CNT_JAGPOSTSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGPOSTSURVEYSRESEARCH END,
		C.CNT_LRPOSTSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRPOSTSURVEYSRESEARCH END,
		C.CNT_JAGSMSSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGSMSSURVEYSRESEARCH END,
		C.CNT_LRSMSSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
											ELSE P.CNT_LRSMSSURVEYSRESEARCH END,
		C.CNT_JAGDIGITALSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
													ELSE P.CNT_JAGDIGITALSURVEYSRESEARCH END,
		C.CNT_LRDIGITALSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRDIGITALSURVEYSRESEARCH END
	FROM CRM.CQI C
		INNER JOIN CTE_PIVOT P ON C.AuditID = P.AuditID
									AND C.AuditItemID = P.AuditItemID
									AND C.item_Id = P.item_Id
	WHERE C.AuditID = @AuditID																-- V1.7


	---------------------------------------------------------------------------------------------------
	--- Calculate Salutation (where applicable)												-- V1.2
	---------------------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #SalutationCalculation

	CREATE TABLE #SalutationCalculation 
	(
		AuditItemID		BIGINT, 
		Gender			CHAR(1), 
		SetToDefault	BIT DEFAULT 0,
		TITLE			NVARCHAR(100) DEFAULT '', 
		NAME_PREFIX		NVARCHAR(100) DEFAULT '',
		NON_ACADEMIC_TITLE NVARCHAR(100) DEFAULT '',
		LAST_NAME		NVARCHAR(100), 
		PREF_LAST_NAME	NVARCHAR(100), 
		ACCT_COUNTRY_CODE VARCHAR(2), 
		SAL_DEAR		NVARCHAR(100) DEFAULT '',
		SAL_TITLE		NVARCHAR(100) DEFAULT '', 
		SAL_NAME_PREFIX NVARCHAR(100) DEFAULT '',
		SAL_NON_ACADEMIC_TITLE NVARCHAR(100) DEFAULT '',
		SAL_LAST_NAME	NVARCHAR(100) ,
		TRN_TITLE		NVARCHAR(100) DEFAULT '',
		TRN_NAME_PREFIX NVARCHAR(100) DEFAULT '',
		TRN_NON_ACADEMIC_TITLE NVARCHAR(100) DEFAULT ''
	)


	-- Get records to update ----------------------------------------------------------------------------------------------------------
	INSERT INTO #SalutationCalculation (AuditItemID, TITLE, NAME_PREFIX, NON_ACADEMIC_TITLE, LAST_NAME, PREF_LAST_NAME, ACCT_COUNTRY_CODE)
	SELECT C.AuditItemID,
		CASE	WHEN C.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(C.ACCT_TITLE, ''))				
				ELSE RTRIM(ISNULL(C.CNT_TITLE, '')) END AS TITLE,
		CASE	WHEN C.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(C.ACCT_NAME_PREFIX, ''))			
				ELSE RTRIM(ISNULL(C.CNT_NAME_PREFIX, '')) END AS NAME_PREFIX,
		CASE	WHEN C.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(C.ACCT_NON_ACADEMIC_TITLE, ''))	
				ELSE RTRIM(ISNULL(C.CNT_NON_ACADEMIC_TITLE, '')) END AS NON_ACADEMIC_TITLE,
		CASE	WHEN C.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(C.ACCT_LAST_NAME, ''))			
				ELSE RTRIM(ISNULL(C.CNT_LAST_NAME, '')) END AS LAST_NAME,
		CASE	WHEN C.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(C.ACCT_PREF_LAST_NAME, ''))		
				ELSE RTRIM(ISNULL(C.CNT_PREF_LAST_NAME, '')) END AS PREF_LAST_NAME,
		ACCT_COUNTRY_CODE
	FROM CRM.CQI C
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = C.ACCT_COUNTRY_CODE 
														AND SCD.Enabled = 1
	WHERE C.DateTransferredToVWT IS NULL	
		AND C.ACCT_COUNTRY_CODE IS NOT NULL


	-- First Pass - Populate title and gender ------------------------------------------------------------------------------------------
	UPDATE SC
	SET SC.SAL_TITLE = SBD.OutputValue,
		SC.TRN_TITLE = SBD.Translation,
		SC.Gender = ISNULL(SBD.Gender, ''),
		SC.SAL_LAST_NAME = CASE WHEN SBD.ClearLastName = 1 THEN '' 
								WHEN SBD.ClearLastName = 0 AND SCD.UsePreferredLastName = 1 THEN SC.PREF_LAST_NAME 
								ELSE SC.LAST_NAME END,
		SC.SetToDefault = CASE	WHEN SBD.SalutationBuildDataID IS NULL THEN 1 
								ELSE 0 END
	FROM #SalutationCalculation SC 
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE 
		LEFT JOIN CRM.SalutationBuildData SBD ON SBD.TitlePart = 'TITLE' 
												AND SBD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE
												AND SBD.TitlePartValue = SC.TITLE
	WHERE SCD.CalcTitle = 1


	-- Second Pass - Populate Name_Prefix ------------------------------------------------------------------------------------------------------------
	UPDATE SC
	SET SC.SAL_NAME_PREFIX = CASE	WHEN SC.SetToDefault = 0 THEN SBD.OutputValue 
									ELSE '' END,
		SC.TRN_NAME_PREFIX = SBD.Translation,
		SC.SAL_TITLE = CASE	WHEN SBD.ClearTitle = 1 THEN '' 
							ELSE SAL_TITLE END ,
		SC.SAL_LAST_NAME = CASE	WHEN SBD.ClearLastName = 1 THEN '' 
								ELSE SAL_LAST_NAME END ,
		SC.SetToDefault = CASE	WHEN SBD.SalutationBuildDataID IS NULL THEN 1 
								ELSE SC.SetToDefault END
	FROM #SalutationCalculation SC 
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE 
		LEFT JOIN CRM.SalutationBuildData SBD ON SBD.TitlePart = 'NAME_PREFIX' 
												AND SBD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE
												AND SBD.TitlePartValue = NAME_PREFIX
												AND (SBD.Gender = SC.Gender OR SBD.Gender = '' OR SC.Gender = '')
	WHERE SCD.CalcNamePrefix = 1
		AND NAME_PREFIX <> ''


	-- Third Pass - Populate Non Academic Title ------------------------------------------------------------------------------------------------------------
	UPDATE SC
	SET SC.SAL_NON_ACADEMIC_TITLE = CASE	WHEN SC.SetToDefault = 0 THEN SBD.OutputValue 
											ELSE '' END,
		SC.TRN_NON_ACADEMIC_TITLE = SBD.Translation,
		SC.SAL_TITLE = CASE	WHEN SBD.ClearTitle = 1 THEN '' 
							ELSE SAL_TITLE END ,
		SC.SAL_NAME_PREFIX = CASE	WHEN SBD.ClearPrefix = 1 THEN '' 
									ELSE SAL_NAME_PREFIX END ,
		SC.SAL_LAST_NAME = CASE	WHEN SBD.ClearLastName = 1 THEN '' 
								ELSE SAL_LAST_NAME END ,
		SC.SetToDefault = CASE	WHEN SBD.SalutationBuildDataID IS NULL THEN 1 
								ELSE SC.SetToDefault END
	FROM #SalutationCalculation SC 
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE  
		LEFT JOIN CRM.SalutationBuildData SBD ON SBD.TitlePart = 'NON_ACADEMIC_TITLE' 
												AND SBD.CountryISOAlpha2 = SC.ACCT_COUNTRY_CODE
												AND SBD.TitlePartValue = SC.NON_ACADEMIC_TITLE
												AND (SBD.Gender = SC.Gender OR SBD.Gender = '' OR SC.Gender = '')
	WHERE SCD.CalcNonAccTitle = 1
		AND NON_ACADEMIC_TITLE <> ''


	-- Populate Salutation value --------------------------------------------------------------------------------------------------------------------
	UPDATE C
	SET C.Calculated_Salutation = CASE WHEN SC.SetToDefault = 1 OR DN.SalutationDearNameID IS NULL 
											THEN REPLACE(SCD.DefaultSalutation, '<brand>', (CASE ISNULL(VEH_BRAND, '')	WHEN 'SAJ' THEN 'Jaguar' 
																														WHEN 'SAL' THEN 'Land Rover' ELSE '' END))
										ELSE LTRIM(REPLACE(
													REPLACE(DN.DearName + ' ' + 
															SAL_TITLE + ' ' +
															SAL_NAME_PREFIX + ' ' +
															SAL_NON_ACADEMIC_TITLE + ' ' +
															SAL_LAST_NAME
															, '   ', ' '), '  ', ' ') )	END,
		C.Calculated_Title = LTRIM(REPLACE(
										REPLACE(ISNULL(TRN_TITLE, '') + ' ' +
												ISNULL(TRN_NAME_PREFIX, '') + ' ' +
												ISNULL(TRN_NON_ACADEMIC_TITLE, '')
												, '   ', ' '), '  ', ' ') )
	FROM #SalutationCalculation SC
		INNER JOIN CRM.CQI C ON C.AuditItemID = SC.AuditItemID
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = C.ACCT_COUNTRY_CODE  
		LEFT JOIN CRM.SalutationDearNames DN ON DN.CountryISOAlpha2 = C.ACCT_COUNTRY_CODE 
											  AND DN.Gender = SC.Gender 

	
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

