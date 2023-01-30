CREATE PROCEDURE   [CRM].[uspDMS_DataConversions]

@AuditID BIGINT			-- V1.6

AS

/*
		Purpose:	Perform any required data conversions, etc, before loading to VWT.
	
		Version		Developer			Created			Comment
LIVE	1.0			Chris Ross			18/06/2015		Created
LIVE	1.1			Chris Ross			31/08/2017		BUG 14122 - Set the PDI flag on the file.  Also added WHERE clause to Date updates
LIVE	1.2			Chris Ross			25/09/2019		BUG 15519 - Apply filtering (set flag) to ensure any records that should not be loaded are excluded from the load to VWT
LIVE	1.3			Chris Ross			19/11/2019		BUG 16731 - Add in additonal Salutation and Title calculation code (used for Germany/Czech/Austria markets).
																	Also, modify convert code to filter those records which haven't yet been loaded to VWT.
LIVE	1.4			Chris Ledger		10/01/2020		BUG 15372 - Fix Hard coded references to databases
LIVE	1.5			Chris Ledger		24/08/2021		TASK 502 - Change to DMS_Repair_Service and add date conversion of DATEOFCONSENT and loading of permission fields
LIVE	1.6			Chris Ledger		27/01/2022		TASK 502 - Only allow YA2 for Italy and use @AuditID to filter updating of permission fields
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
	-- V1.6 GET COUNTRYCODE FROM AUDITID
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


	UPDATE DRS
	SET Converted_VISTACONTRACT_HANDOVER_DATE = NULLIF(VISTACONTRACT_HANDOVER_DATE, '0000-00-00'),
		Converted_CASE_CASE_SOLVED_DATE = NULLIF(CASE_CASE_SOLVED_DATE, '0000-00-00'),
		Converted_ROADSIDE_DATE_JOB_COMPLETED = NULLIF(ROADSIDE_DATE_JOB_COMPLETED, '0000-00-00'),
		Converted_DMS_REPAIR_ORDER_CLOSED_DATE = NULLIF(DMS_REPAIR_ORDER_CLOSED_DATE, '0000-00-00'),
		Converted_VEH_BUILD_DATE = NULLIF(VEH_BUILD_DATE, '0000-00-00'),
		Converted_VEH_REGISTRATION_DATE = NULLIF(VEH_REGISTRATION_DATE,  '0000-00-00'),
		Converted_ACCT_DATE_ADVISED_OF_DEATH = NULLIF(ACCT_DATE_ADVISED_OF_DEATH, '0000-00-00'),
		Converted_ACCT_DATE_OF_BIRTH = NULLIF(ACCT_DATE_OF_BIRTH, '0000-00-00')
	FROM CRM.DMS_Repair_Service DRS
	WHERE DRS.DateTransferredToVWT IS NULL				-- V1.1
		AND DRS.ACCT_COUNTRY_CODE IS NOT NULL			-- V1.3

	
	-- Set the PDI flag on the file						-- V1.1
	UPDATE DRS
	SET PDI_Flag = 'Y' 
	FROM CRM.DMS_Repair_Service DRS
	WHERE DRS.DMS_OTHER_RELATED_SERVICES IS NOT NULL
		AND (	DRS.DMS_OTHER_RELATED_SERVICES LIKE '%PDI%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Pre-Delivery Inspect%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Predelivery inspect%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Pre delivery inspect%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Prep for deliv%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Clean for deliv%'
			 OR DRS.DMS_OTHER_RELATED_SERVICES LIKE '%Prepare for deliv%')
		AND DRS.DateTransferredToVWT IS NULL
		AND DRS.ACCT_COUNTRY_CODE IS NOT NULL				-- V1.3


	---------------------------------------------------------------------------------------------------
	--- Update DMS_ACCT_MKT_PERM_ITEM.DATEOFCONSENT												-- V1.5
	---------------------------------------------------------------------------------------------------
	UPDATE AMPI
	SET AMPI.Converted_DATEOFCONSENT = NULLIF(AMPI.DATEOFCONSENT, '0000-00-00')
	FROM CRM.DMS_Repair_Service DRS	
		INNER JOIN CRM.DMS_ACCT_MKT_PERM AMP ON DRS.AuditID = AMP.AuditID
														AND DRS.item_Id = AMP.item_Id
		INNER JOIN CRM.DMS_ACCT_MKT_PERM_ITEM AMPI ON DRS.AuditID = AMPI.AuditID
														AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
	WHERE DRS.AuditID = @AuditID																-- V1.6


	---------------------------------------------------------------------------------------------------
	--- Update DMS_ACCT_MKT_PERM_ITEM.DATEOFCONSENT												-- V1.5
	---------------------------------------------------------------------------------------------------
	UPDATE CMPI
	SET CMPI.Converted_DATEOFCONSENT = NULLIF(CMPI.DATEOFCONSENT, '0000-00-00')
	FROM CRM.DMS_Repair_Service DRS	
		INNER JOIN CRM.DMS_CNT_MKT_PERM CMP ON DRS.AuditID = CMP.AuditID
															AND DRS.item_Id = CMP.item_Id
		INNER JOIN CRM.DMS_CNT_MKT_PERM_ITEM CMPI ON DRS.AuditID = CMPI.AuditID
															AND CMP.CNT_MKT_PERM_Id = CMPI.CNT_MKT_PERM_Id
	WHERE DRS.AuditID = @AuditID																-- V1.6


	---------------------------------------------------------------------------------------------------
	--- Update Personal Permission Fields														-- V1.5
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
			SELECT DRS.ID,
				DRS.AuditID,
				DRS.AuditItemID,
				DRS.item_Id,
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
			FROM CRM.DMS_Repair_Service DRS
				INNER JOIN CRM.DMS_ACCT_MKT_PERM AMP ON DRS.AuditID = AMP.AuditID
																	AND DRS.item_Id = AMP.item_Id
				LEFT JOIN CRM.DMS_ACCT_MKT_PERM_ITEM AMPI ON DRS.AuditID = AMPI.AuditID
																	AND AMP.ACCT_MKT_PERM_Id = AMPI.ACCT_MKT_PERM_Id
			WHERE DRS.AuditID = @AuditID																								-- V1.6
				AND ((@CountryCode = 'IT' AND AMPI.COMMCHANNEL = 'YA2')																	-- V1.6
					OR (@CountryCode <> 'IT' AND AMPI.COMMCHANNEL IN ('Y06','Y16','Y26','Y36','Y46','Y56','Y66','Y76','Y86','Y96')))	-- V1.6
		) D
		PIVOT
		(
			MAX(CONSENT)
			FOR Field IN (JAGPHONESURVEYSRESEARCH, LRPHONESURVEYSRESEARCH, JAGEMAILSURVEYSRESEARCH, LREMAILSURVEYSRESEARCH, JAGPOSTSURVEYSRESEARCH, LRPOSTSURVEYSRESEARCH, JAGSMSSURVEYSRESEARCH, LRSMSSURVEYSRESEARCH, JAGDIGITALSURVEYSRESEARCH, LRDIGITALSURVEYSRESEARCH, CUSTOMERSATISFACTIONSURVEY)
		) P
	)
	UPDATE DRS
	SET DRS.JAGPHONESURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGPHONESURVEYSRESEARCH END,
		DRS.LRPHONESURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRPHONESURVEYSRESEARCH END,
		DRS.JAGEMAILSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGEMAILSURVEYSRESEARCH END,
		DRS.LREMAILSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LREMAILSURVEYSRESEARCH END,
		DRS.JAGPOSTSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGPOSTSURVEYSRESEARCH END,
		DRS.LRPOSTSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRPOSTSURVEYSRESEARCH END,
		DRS.JAGSMSSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.JAGSMSSURVEYSRESEARCH END,
		DRS.LRSMSSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
										ELSE P.LRSMSSURVEYSRESEARCH END,
		DRS.JAGDIGITALSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
												ELSE P.JAGDIGITALSURVEYSRESEARCH END,
		DRS.LRDIGITALSURVEYSRESEARCH = CASE	WHEN P.CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CUSTOMERSATISFACTIONSURVEY
											ELSE P.LRDIGITALSURVEYSRESEARCH END
	FROM CRM.DMS_Repair_Service DRS
		INNER JOIN CTE_PIVOT P ON DRS.AuditID = P.AuditID
									AND DRS.AuditItemID = P.AuditItemID
									AND DRS.item_Id = P.item_Id 
	WHERE DRS.AuditID = @AuditID																-- V1.6


	---------------------------------------------------------------------------------------------------
	--- Update Company Permission Fields														-- V1.5
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
			SELECT DRS.ID,
				DRS.AuditID,
				DRS.AuditItemID,
				DRS.item_Id,
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
			FROM CRM.DMS_Repair_Service DRS
			INNER JOIN CRM.DMS_CNT_MKT_PERM CMP ON DRS.AuditID = CMP.AuditID
																AND DRS.item_Id = CMP.item_Id
			LEFT JOIN CRM.DMS_CNT_MKT_PERM_ITEM CMPI ON DRS.AuditID = CMPI.AuditID
																AND CMP.CNT_MKT_PERM_Id = CMPI.CNT_MKT_PERM_Id
			WHERE DRS.AuditID = @AuditID																								-- V1.6
				AND ((@CountryCode = 'IT' AND CMPI.COMMCHANNEL = 'YA2')																	-- V1.6
					OR (@CountryCode <> 'IT' AND CMPI.COMMCHANNEL IN ('Y06','Y16','Y26','Y36','Y46','Y56','Y66','Y76','Y86','Y96')))	-- V1.6
		) D
		PIVOT
		(
		  MAX(CONSENT)
		  FOR Field IN (CNT_JAGPHONESURVEYSRESEARCH, CNT_LRPHONESURVEYSRESEARCH, CNT_JAGEMAILSURVEYSRESEARCH, CNT_LREMAILSURVEYSRESEARCH, CNT_JAGPOSTSURVEYSRESEARCH, CNT_LRPOSTSURVEYSRESEARCH, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRSMSSURVEYSRESEARCH,	CNT_JAGDIGITALSURVEYSRESEARCH, CNT_LRDIGITALSURVEYSRESEARCH, CNT_CUSTOMERSATISFACTIONSURVEY)
		) P
	)
	UPDATE DRS
	SET DRS.CNT_JAGPHONESURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGPHONESURVEYSRESEARCH END,
		DRS.CNT_LRPHONESURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRPHONESURVEYSRESEARCH END,
		DRS.CNT_JAGEMAILSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGEMAILSURVEYSRESEARCH END,
		DRS.CNT_LREMAILSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LREMAILSURVEYSRESEARCH END,
		DRS.CNT_JAGPOSTSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGPOSTSURVEYSRESEARCH END,
		DRS.CNT_LRPOSTSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRPOSTSURVEYSRESEARCH END,
		DRS.CNT_JAGSMSSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_JAGSMSSURVEYSRESEARCH END,
		DRS.CNT_LRSMSSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
											ELSE P.CNT_LRSMSSURVEYSRESEARCH END,
		DRS.CNT_JAGDIGITALSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
													ELSE P.CNT_JAGDIGITALSURVEYSRESEARCH END,
		DRS.CNT_LRDIGITALSURVEYSRESEARCH = CASE	WHEN P.CNT_CUSTOMERSATISFACTIONSURVEY IS NOT NULL THEN P.CNT_CUSTOMERSATISFACTIONSURVEY
												ELSE P.CNT_LRDIGITALSURVEYSRESEARCH END
	FROM CRM.DMS_Repair_Service DRS
		INNER JOIN CTE_PIVOT P ON DRS.AuditID = P.AuditID
									AND DRS.AuditItemID = P.AuditItemID
									AND DRS.item_Id = P.item_Id
	WHERE DRS.AuditID = @AuditID															-- V1.6


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
	SELECT DRS.AuditItemID,
		CASE	WHEN DRS.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(DRS.ACCT_TITLE, ''))				
				ELSE RTRIM(ISNULL(DRS.CNT_TITLE, '')) END AS TITLE,
		CASE	WHEN DRS.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(DRS.ACCT_NAME_PREFIX, ''))			
				ELSE RTRIM(ISNULL(DRS.CNT_NAME_PREFIX, '')) END AS NAME_PREFIX,
		CASE	WHEN DRS.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(DRS.ACCT_NON_ACADEMIC_TITLE, ''))	
				ELSE RTRIM(ISNULL(DRS.CNT_NON_ACADEMIC_TITLE, '')) END AS NON_ACADEMIC_TITLE,
		CASE	WHEN DRS.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(DRS.ACCT_LAST_NAME, ''))			
				ELSE RTRIM(ISNULL(DRS.CNT_LAST_NAME, '')) END AS LAST_NAME,
		CASE	WHEN DRS.ACCT_ACCT_TYPE = 'Person' THEN RTRIM(ISNULL(DRS.ACCT_PREF_LAST_NAME, ''))		
				ELSE RTRIM(ISNULL(DRS.CNT_PREF_LAST_NAME, '')) END AS PREF_LAST_NAME,
		ACCT_COUNTRY_CODE
	FROM CRM.DMS_Repair_Service DRS
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = DRS.ACCT_COUNTRY_CODE 
														AND SCD.Enabled = 1
	WHERE DRS.DateTransferredToVWT IS NULL	
		AND DRS.ACCT_COUNTRY_CODE IS NOT NULL


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
		AND SC.NAME_PREFIX <> ''


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
		AND SC.NON_ACADEMIC_TITLE <> ''


	-- Populate Salutation value --------------------------------------------------------------------------------------------------------------------
	UPDATE DRS
	SET DRS.Calculated_Salutation = CASE WHEN SC.SetToDefault = 1 OR DN.SalutationDearNameID IS NULL 
											THEN REPLACE(SCD.DefaultSalutation, '<brand>', (CASE ISNULL(VEH_BRAND, '')	WHEN 'SAJ' THEN 'Jaguar' 
																														WHEN 'SAL' THEN 'Land Rover' ELSE '' END))
										ELSE LTRIM(REPLACE(
													REPLACE(DN.DearName + ' ' + 
															SAL_TITLE + ' ' +
															SAL_NAME_PREFIX + ' ' +
															SAL_NON_ACADEMIC_TITLE + ' ' +
															SAL_LAST_NAME
															, '   ', ' '), '  ', ' ') )	END,
		DRS.Calculated_Title = LTRIM(REPLACE(
										REPLACE(ISNULL(TRN_TITLE, '') + ' ' +
												ISNULL(TRN_NAME_PREFIX, '') + ' ' +
												ISNULL(TRN_NON_ACADEMIC_TITLE, '')
												, '   ', ' '), '  ', ' ') )
	FROM #SalutationCalculation SC
		INNER JOIN CRM.DMS_Repair_Service DRS ON DRS.AuditItemID = SC.AuditItemID
		INNER JOIN CRM.SalutationCountryDefaults SCD ON SCD.CountryISOAlpha2 = DRS.ACCT_COUNTRY_CODE  
		LEFT JOIN CRM.SalutationDearNames DN ON DN.CountryISOAlpha2 = DRS.ACCT_COUNTRY_CODE 
											  AND DN.Gender = SC.Gender 


	--------------------------------------------------------------------------------------------------------
	--- Apply filtering (flag) to ensure any records that should not be loaded are excluded from the load
	--------------------------------------------------------------------------------------------------------
	BEGIN TRAN 

		-- Remove Dallas Body shop records
		IF 1 = (	SELECT Enabled 
					FROM CRM.Filters
					WHERE FilterName = 'Dallas Body Shop Service Advisors')
		BEGIN
		
			CREATE TABLE #FilteredRecs
			(
				CRM_ID   BIGINT
			)
		
			DECLARE @Datetime DATETIME
			SET @Datetime = GETDATE()

			-- Identify the records to filter
			INSERT INTO #FilteredRecs
			SELECT DRS.ID
			FROM CRM.DMS_Repair_Service DRS
			WHERE DRS.DateTransferredToVWT IS NULL
				AND DRS.FilteredOut = 0
				AND DRS.DMS_SECON_DEALER_CODE IN (	SELECT FV.FilterValue 
													FROM CRM.Filters F
														INNER JOIN CRM.FilterValues FV ON FV.FilterID = F.FilterID
													WHERE F.FilterName = 'Dallas Body Shop Service Advisors'
														AND FV.ColumnName = 'DMS_SECON_DEALER_CODE')
				AND DRS.DMS_SERVICE_ADVISOR_ID IN (	SELECT FV.FilterValue 
													FROM CRM.Filters F
														INNER JOIN CRM.FilterValues FV ON FV.FilterID = F.FilterID
													WHERE F.FilterName = 'Dallas Body Shop Service Advisors'
														AND FV.ColumnName = 'DMS_SERVICE_ADVISOR_ID') 
		
			
			-- Record the filtered recs in the filter reference table
			INSERT INTO CRM.FilteredRecords (CRMTableName, CRMTableID, AuditID, AuditItemID, PhysicalRowID, DateFiltered, FilteredReason)
			SELECT 'CRM.DMS_Repair_Service' AS  CRMTableName, 
				DRS.ID AS CRMTableID, 
				DRS.AuditID, 
				DRS.AuditItemID, 
				DRS.PhysicalRowID, 
				@Datetime AS DateFiltered, 
				'Dallas Body Shop Service Advisors' AS FilteredReason			
			FROM CRM.DMS_Repair_Service DRS
			WHERE ID IN (SELECT CRM_ID FROM #FilteredRecs)
	
	
			-- Update the filtered flag in the CRM staging table
			UPDATE DRS
			SET DRS.FilteredOut = 1
			FROM CRM.DMS_Repair_Service DRS
			WHERE ID IN (SELECT CRM_ID FROM #FilteredRecs)

		END

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

