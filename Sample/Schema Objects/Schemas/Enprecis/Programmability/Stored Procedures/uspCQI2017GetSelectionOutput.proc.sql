CREATE PROCEDURE [Enprecis].[uspCQI2017GetSelectionOutput]
	@SurveyType VARCHAR(20), 
	@RussiaOutput INTEGER = 0	-- V1.6
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
		Purpose:	Produces On-line output for CQI 2017 
		
		Version		Date				Developer			Comment
LIVE	1.0			16/01/2017			Chris Ledger		Created
LIVE	1.1			25/01/2017			Chris Ledger		BUG 13160: Add Model Summary
LIVE	1.2			27/01/2017			Chris Ledger		BUG 13160: Add Interval
LIVE	1.3			12/06/2017			Chris Ledger		BUG 14000: Add UnknownLang for US/Canada
LIVE	1.4			21/11/2017			Chris Ledger		BUG 14347: Add MCQI
LIVE	1.5			22/08/2019			Chris Ledger		Make INSERT INTO SelectionOutput.OnlineOutput DISTINCT
LIVE	1.6			12/09/2019			Chris Ledger		BUG 15571: Add CQI Russia
LIVE	1.7			29/11/2019			Chris Ledger		BUG 16673: Add New CQI Surveys
LIVE	1.8			21/01/2020			Chris Ledger		BUG 15372: Fix Hard coded references to databases
LIVE	1.9			18/02/2020			Chris Ledger		BUG 17942: Add MCQI 1MIS Survey
LIVE	1.10		12/03/2020			Ben King			BUG 18000 - Map Business Region to 'blank' variable
LIVE	1.11		19/05/2021			Chris Ledger		TASK 441: Identify CQI from Questionnaire field
LIVE	1.12		08/06/2021			Chris Ledger		TASK 476: Include old method of identifying CQI
LIVE	1.13		04/01/2022			Chris Ledger		TASK 736: Truncate SelectionOutput tables to fix bug if normal selection output fails
LIVE	1.14		20/06/2022			Chris Ledger		TASK 729: Ammend BodyDoors for model description changes
LIVE	1.15		20/06/2022			Chris Ledger		TASK 917: Add CQI1MIS
LIVE	1.16		17/10/2022			Chris Ledger		TASK 1017: Update Sub Brand
*/

	-------------------------------------------------------------------
	-- SCRIPT FOR CQI OUTPUT TAKEN FROM [SelectionOutput].[uspRunOutput], [SelectionOutput].[uspPopulateOnlineFile] & [SelectionOutput].[uspOnlineEmailContactDetails]
	-------------------------------------------------------------------

	-------------------------------------------------------------------
	-- V1.13 CLEAR DOWN SELECTIONOUTPUT TABLES PRIOR TO RUNNING OUTPUT
	-------------------------------------------------------------------
	TRUNCATE TABLE SelectionOutput.Base
	TRUNCATE TABLE SelectionOutput.Email
	TRUNCATE TABLE SelectionOutput.OnlineOutput
	-------------------------------------------------------------------


	-------------------------------------------------------------------
	-- GET ALL SelectionRequirementIDs FOR LATEST CQI SELECTIONS
	-------------------------------------------------------------------
	
	DROP TABLE IF EXISTS #SelectionRequirementIDs


	CREATE TABLE #SelectionRequirementIDs
	(
		[ID] INT IDENTITY(1,1) NOT NULL,
		SelectionRequirementID INT
	)

	INSERT INTO #SelectionRequirementIDs
	SELECT DISTINCT RS.RequirementID AS 'SelectionRequirementID'
	FROM dbo.vwBrandMarketQuestionnaireSampleMetadata M
		INNER JOIN Requirement.Requirements RQ ON M.QuestionnaireRequirementID = RQ.RequirementID
		INNER JOIN Requirement.RequirementRollups RR ON RQ.RequirementID = RR.RequirementIDPartOf
		INNER JOIN Requirement.Requirements RS ON RR.RequirementIDMadeUpOf = RS.RequirementID
		INNER JOIN Requirement.SelectionRequirements SR ON RS.RequirementID = SR.RequirementID
	WHERE (M.Questionnaire LIKE '%CQI%'	OR SUBSTRING(RQ.Requirement,1,3) = 'CQI' OR SUBSTRING(RQ.Requirement,1,4) = 'MCQI')		-- V1.11 -- V1.12
		AND ((@RussiaOutput = 1 AND RS.Requirement LIKE '%RUS%') OR (@RussiaOutput = 0 AND RS.Requirement NOT LIKE '%RUS%'))	-- V1.6
		AND RQ.RequirementTypeID = 2
		AND SR.SelectionStatusTypeID = 2

	DECLARE @SelectionRequirementID INT
	DECLARE @Counter INT
	
	SET @Counter = 1
	
	------------------------------------------------------------------------------------
	-- LOOP THROUGH SELECTION REQUIREMENTIDS 
	------------------------------------------------------------------------------------
	WHILE @Counter <= (SELECT COUNT(*) FROM #SelectionRequirementIDs)
	BEGIN

		SELECT
			@SelectionRequirementID = SelectionRequirementID
		FROM #SelectionRequirementIDs 
		WHERE [ID] = @Counter

		-- GET THE CASE DETAILS
		INSERT INTO SelectionOutput.Base
		(
			PartyID,
			CaseID,
			ModelDescription,
			VIN,
			Manufacturer,
			RegistrationNumber,
			Title,
			FirstName,
			LastName,
			Addressee,
			Salutation,
			OrganisationName,
			PostalAddressContactMechanismID,
			BuildingName,
			SubStreet,
			Street,
			SubLocality,
			Locality,
			Town,
			Region,
			PostCode,
			Country,
			DealerCode,							-- V1.1
			DealerName,
			VersionCode,
			CountryID,
			ModelRequirementID,
			LanguageID,
			ManufacturerPartyID,
			GenderID,
			QuestionnaireVersion,
			EventTypeID,
			EventDate,							-- V1.1
			SelectionTypeID,
			EmailAddressContactMechanismID,
			EmailAddress,
			LandPhone,							-- V1.1
			MobilePhone,						-- V1.1
			WorkPhone,							-- V1.1
			GDDDealerCode,						-- V1.3
			ReportingDealerPartyID,				-- V1.3
			VariantID,							-- V1.3
			ModelVariant,						-- V1.3
			BilingualFlag,						-- V1.4
			LanguageIDBilingual,				-- V1.4
			SalutationBilingual					-- V1.4
		)
		EXEC Event.uspGetSelectionCases @SelectionRequirementID			


		-- GET or SET the SelectionOutputPassword value --------------------- V1.2
		UPDATE B
		SET B.SelectionOutputPassword = CASE	WHEN ISNULL(C.SelectionOutputPassword, '') <> '' THEN C.SelectionOutputPassword
												ELSE SelectionOutput.udfGeneratePassword() END 
		FROM SelectionOutput.Base B
			INNER JOIN Event.Cases C ON C.CaseID = B.CaseID

		-- INCREMENT THE COUNTER
		SET @Counter = @Counter + 1

	END


	---------------------------------------------------------------
	-- EMAIL OUTPUT WITH CHECKS FOR VALID EMAILS REMOVED
	---------------------------------------------------------------
	INSERT INTO SelectionOutput.Email
	(
		Password,
		[ID],
		FullModel,
		Model,
		VIN,
		sType,
		CarReg,
		Title,
		Initial,
		Surname,
		Fullname,
		DearName,
		CoName,
		Add1,
		Add2,
		Add3,
		Add4,
		Add5,
		Add6,
		Add7,
		Add8,
		Add9,
		CTRY,
		EmailAddress,
		Dealer,
		sno,
		ccode,
		modelcode,
		lang,
		manuf,
		gender,
		qver,
		blank,
		etype,
		reminder,
		[week],
		test,
		SampleFlag,
		SalesServiceFile,
		DealerCode,
		EventDate,
		LandPhone,
		WorkPhone,
		MobilePhone,
		PartyID,
		GDDDealerCode,				-- V1.3
		ReportingDealerPartyID,		-- V1.3
		VariantID,					-- V1.3
		ModelVariant				-- V1.3
	)
	SELECT DISTINCT
		B.SelectionOutputPassword AS [Password],
		B.CaseID AS [ID],
		B.ModelDescription AS FullModel,
		B.ModelDescription AS Model,
		B.VIN,
		B.Manufacturer AS sType,
		B.RegistrationNumber AS CarReg,
		B.Title,
		B.FirstName AS Initial,
		B.LastName AS Surname,
		B.Addressee AS Fullname,
		B.Salutation AS DearName,
		B.OrganisationName AS CoName,
		B.BuildingName AS Add1,
		B.SubStreet AS Add2,
		B.Street AS Add3,
		B.SubLocality AS Add4,
		B.Locality AS Add5,
		B.Town AS Add6,
		B.Region AS Add7,
		B.PostCode AS Add8,
		'' AS Add9,
		B.Country AS CTRY,
		B.EmailAddress,
		B.DealerName AS Dealer,
		B.VersionCode AS sno,
		B.CountryID AS ccode,
		B.ModelRequirementID AS modelcode,
		B.LanguageID AS lang,
		B.ManufacturerPartyID AS manuf,
		B.GenderID AS gender,
		B.QuestionnaireVersion AS qver,
		'' AS blank,
		B.EventTypeID AS etype,
		1 AS reminder,
		SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
		0 AS test,
		1 AS SampleFlag,
		'' AS SalesServiceFile,
		B.DealerCode,
		B.EventDate,
		B.LandPhone,
		B.WorkPhone,
		B.MobilePhone,
		B.PartyID,
		B.GDDDealerCode,			-- V1.3
		B.ReportingDealerPartyID,	-- V1.3
		B.VariantID,				-- V1.3
		B.ModelVariant				-- V1.3
	FROM SelectionOutput.Base B
	WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 


	--------------------------------------------------------------------------
	-- Clear down Base Table
	TRUNCATE TABLE SelectionOutput.Base
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	-- POPULATE ONLINE FILE 
	--------------------------------------------------------------------------
	INSERT INTO SelectionOutput.OnlineOutput
	(
		[Password], 
		[ID], 
		FullModel, 
		Model,
		VIN, 
		sType, 
		CarReg, 
		Title, 
		Initial, 
		Surname, 
		Fullname, 
		DearName, 
		CoName, 
		Add1, 
		Add2, 
		Add3, 
		Add4, 
		Add5, 
		Add6, 
		Add7, 
		Add8, 
		Add9, 
		CTRY, 
		EmailAddress, 
		Dealer, 
		sno, 
		ccode, 
		modelcode, 
		lang, 
		manuf, 
		gender, 
		qver, 
		blank, 
		etype, 
		reminder, 
		week, 
		test, 
		SampleFlag, 
		SalesServiceFile,
		ITYPE,
		Market,
		Expired,
		EventDate,
		DealerCode,
		Telephone,
		WorkTel,
		MobilePhone,
		PartyID,
		GDDDealerCode,
		ReportingDealerPartyID,
		VariantID,
		ModelVariant,
		CATIType
	)
	SELECT DISTINCT
		SO.[Password], 
		SO.[ID], 
		SO.FullModel, 
		SO.Model, 
		SO.VIN,
		SO.sType, 
		SO.CarReg, 
		SO.Title, 
		SO.Initial, 
		SO.Surname, 
		SO.Fullname, 
		SO.DearName, 
		SO.CoName, 
		SO.Add1, 
		SO.Add2, 
		SO.Add3, 
		SO.Add4, 
		SO.Add5, 
		SO.Add6, 
		SO.Add7, 
		SO.Add8, 
		SO.Add9, 
		SO.CTRY, 
		SO.EmailAddress, 
		SO.Dealer, 
		SO.sno, 
		SO.ccode, 
		SO.modelcode, 
		SO.lang, 
		SO.manuf, 
		SO.gender, 
		SO.qver, 
		SO.blank, 
		SO.etype, 
		SO.reminder, 
		SO.week, 
		SO.test, 
		SO.SampleFlag, 
		SO.SalesServiceFile,
		'H' AS ITYPE,
		BMQ.ISOAlpha3,
		DATEADD(D, BMQ.NumDaysToExpireOnlineQuestionnaire, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) AS Expired,
		SO.EventDate,
		SO.DealerCode,
		LandPhone,
		WorkPhone,
		MobilePhone,
		SO.PartyID,
		SO.GDDDealerCode,
		SO.ReportingDealerPartyID,
		SO.VariantID,
		SO.ModelVariant,
		0 AS CATIType
	FROM SelectionOutput.Email SO
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
		INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
		LEFT JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType
																	AND BMQ.CountryID = SO.ccode
																	AND BMQ.Questionnaire = ET.EventCategory
	WHERE ISNULL(BMQ.IncludeEmailOutputInAllFile, 0) = 1


	--------------------------------------------------------------------------
	-- Add in additional information required for On-line    -- V1.3
	--------------------------------------------------------------------------
	UPDATE O
	SET ManufacturerDealerCode = F.ManufacturerDealerCode, 
		ModelYear = MY.ModelYear, 
		CustomerIdentifier = CR.CustomerIdentifier, 
		OwnershipCycle  = CD.OwnershipCycle,
		OutletPartyID = CD.DealerPartyID,					-- V1.4
		blank = ISNULL(F.BusinessRegion,'')					-- V1.10
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = O.ID
		INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = etype 
		INNER JOIN Event.EventCategories EC ON ETC.EventCategoryID = EC.EventCategoryID
		LEFT JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Flat F	ON F.DealerCode = O.DealerCode
																		AND F.OutletPartyID = CD.DealerPartyID 
																		AND F.OutletFunction = CASE EC.EventCategory	WHEN 'Service' THEN 'Aftersales'
																														ELSE EC.EventCategory END
																		--	AND F.ManufacturerDealerCode IS NOT NULL   -- V1.9
		LEFT JOIN Vehicle.ModelYear MY ON MY.VINCharacter = SUBSTRING(O.VIN, MY.VINPosition, 1) 
											AND CD.ManufacturerPartyID = MY.ManufacturerPartyID
		LEFT JOIN [$(AuditDB)].Audit.CustomerRelationships CR ON CR.PartyIDFrom = CD.PartyID 
																AND CR.CustomerIdentifierUsable = 1 
																AND CR.AuditItemID = (	SELECT MAX(AuditItemID) 
																						FROM  [$(AuditDB)].Audit.CustomerRelationships CR2 
																						WHERE CR2.PartyIDFrom = CR.PartyIDFrom 
																							AND CR2.CustomerIdentifierUsable = CR.CustomerIdentifierUsable)
	--------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------
	-- V1.10
	-- UPDATE BusinessRegion for All other questionnaires not within Dealer Hierarchy.
	-- NB: BusinessRegion is unique to Market
	--------------------------------------------------------------------------
	UPDATE O
	SET	blank = ISNULL(F.BusinessRegion,'')
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN dbo.Markets M ON M.Market = O.CTRY
		INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Flat F ON F.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
	WHERE ISNULL(blank,'') = ''
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	-- UPDATE MODEL SUMMARY
	--------------------------------------------------------------------------
	;WITH CTE_Model (ModelDescription, CodeName, VIN, ModelYear, BodyDoors) AS 
	(
		SELECT M.ModelDescription, 
			M.CodeName, 
			V.VIN, 
			MY.ModelYear,
			CASE M.ModelDescription	WHEN 'Discovery' THEN 'SV5'															-- V1.14
									WHEN 'Discovery Sport' THEN 'SV5'
									WHEN 'Evoque Convertible' THEN 'SC2'
									WHEN 'F-PACE' THEN 'SV5'
									WHEN 'F-TYPE' THEN CASE SUBSTRING(V.VIN,6,2)	WHEN '60' THEN 'CP2'
																					WHEN '61' THEN 'CP2'
																					WHEN '63' THEN 'CP2'
																					WHEN '64' THEN 'CV2'
																					WHEN '65' THEN 'CV2'
																					WHEN '66' THEN 'CV2'
																					WHEN '67' THEN 'CV2' END
									WHEN 'Range Rover' THEN 'SV5'
									WHEN 'Range Rover Evoque' THEN CASE SUBSTRING(V.VIN, 6, 1)	WHEN '1' THEN 'SV3'
																								WHEN '2' THEN 'SV5' END
									WHEN 'Range Rover Sport' THEN 'SV5'
									WHEN 'XE' THEN 'SA4'
									WHEN 'XF' THEN CASE MV.Variant	WHEN 'XF SPORTBRAKE (X260)' THEN 'SB5'				-- V1.14
																	ELSE 'SA4' END										-- V1.14
									WHEN 'XJ' THEN 'SA4'
									ELSE ''	END AS BodyDoors	
	FROM Vehicle.Vehicles V
		INNER JOIN Vehicle.Models M ON V.ModelID = M.ModelID
		INNER JOIN Vehicle.ModelYear MY ON SUBSTRING(V.VIN, 10, 1) = MY.VINCharacter 
											AND M.ManufacturerPartyID = MY.ManufacturerPartyID
		LEFT JOIN Vehicle.ModelVariants MV ON M.ModelID = MV.ModelID													-- V1.14
											AND V.ModelVariantID = MV.VariantID											-- V1.14
	WHERE V.VehicleIdentificationNumberUsable = 1
		AND M.CodeName IS NOT NULL
	)
	UPDATE O 
	SET O.ModelSummary = CONVERT(VARCHAR(4),CTE.CodeName) + CONVERT(VARCHAR(3),CTE.BodyDoors) + CONVERT(VARCHAR(4),CTE.ModelYear)
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN CTE_Model CTE ON O.VIN = CTE.VIN
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	-- UPDATE INTERVAL
	--------------------------------------------------------------------------
	UPDATE O 
	SET O.IntervalPeriod = CASE R.Requirement	WHEN 'CQI LR 1MIS 2017+' THEN '1MIS'
												WHEN 'CQI JAG 1MIS 2017+' THEN '1MIS'
												WHEN 'CQI LR 3MIS 2017+' THEN '3MIS'
												WHEN 'CQI JAG 3MIS 2017+' THEN '3MIS'
												WHEN 'CQI LR 12MIS 2017+' THEN '12MIS'
												WHEN 'CQI JAG 12MIS 2017+' THEN '12MIS'
												WHEN 'CQI LR 24MIS 2017+' THEN '24MIS'
												WHEN 'CQI JAG 24MIS 2017+' THEN '24MIS'
												WHEN 'MCQI LR 1MIS 2017+' THEN '1MIS_MCQI'		-- V1.4
												WHEN 'MCQI JAG 1MIS 2017+' THEN '1MIS_MCQI'		-- V1.4
												WHEN 'MCQI LR 3MIS 2017+' THEN '3MIS_MCQI'		-- V1.4
												WHEN 'MCQI JAG 3MIS 2017+' THEN '3MIS_MCQI'		-- V1.4
												WHEN 'MCQI LR 12MIS 2017+' THEN '12MIS_MCQI'	-- V1.4
												WHEN 'MCQI JAG 12MIS 2017+' THEN '12MIS_MCQI'	-- V1.4
												WHEN 'MCQI LR 24MIS 2017+' THEN '24MIS_MCQI'	-- V1.4
												WHEN 'MCQI JAG 24MIS 2017+' THEN '24MIS_MCQI'	-- V1.4
												WHEN 'CQI 3MIS Survey' THEN '3MIS'				-- V1.7
												WHEN 'CQI 24MIS Survey' THEN '24MIS'			-- V1.7
												WHEN 'MCQI 1MIS Survey' THEN '1MIS_MCQI'		-- V1.9
												WHEN 'CQI 1MIS Survey' THEN '1MIS'				-- V1.15
												ELSE '' END 
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = O.ID
		INNER JOIN Requirement.Requirements RS ON SC.RequirementIDPartOf = RS.RequirementID
		INNER JOIN Requirement.RequirementRollups RR2 ON SC.RequirementIDPartOf = RR2.RequirementIDMadeUpOf
		INNER JOIN Requirement.Requirements RQ ON RR2.RequirementIDPartOf = RQ.RequirementID
		INNER JOIN Requirement.RequirementRollups RR1 ON RR2.RequirementIDPartOf = RR1.RequirementIDMadeUpOf
		INNER JOIN Requirement.Requirements R ON RR1.RequirementIDPartOf = R.RequirementID
	WHERE (R.Requirement LIKE 'CQI%2017+' 
			OR R.Requirement LIKE 'MCQI%2017+' 
			OR R.Requirement LIKE 'CQI%Survey' 
			OR R.Requirement LIKE 'MCQI%Survey')		-- V1.4, V1.7, V1.9

	--------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------
	-- V1.3 Update US UnknownLang
	--------------------------------------------------------------------------
	DROP TABLE IF EXISTS #Vista_Contract_Sales

	CREATE TABLE #Vista_Contract_Sales
	(	
		RowID INT,
		VIN VARCHAR(50),
		UnknownLang VARCHAR(100)
	);
		
	INSERT INTO #Vista_Contract_Sales (RowID, VIN, UnknownLang)
	SELECT ROW_NUMBER() OVER (PARTITION BY O.VIN ORDER BY S.AuditItemID DESC) AS RowID, 
		O.VIN AS VIN,
		CASE	WHEN NULLIF(S.ACCT_PREF_LANGUAGE_CODE,'') IS NULL THEN 1 
				ELSE 0 END AS UnknownLang    
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'Sales'
		INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales S ON S.VEH_VIN = O.VIN
	WHERE O.CTRY = 'United States of America'

	UPDATE O 
	SET O.UnknownLang = VCS.UnknownLang
	FROM SelectionOutput.OnlineOutput O
		LEFT JOIN #Vista_Contract_Sales VCS ON O.VIN = VCS.VIN
	WHERE VCS.RowID = 1
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	-- V1.16 - Update SubBrand
	--------------------------------------------------------------------------
	UPDATE O
	SET O.SubBrand = SB.SubBrand
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN	Vehicle.Vehicles V ON O.VIN = V.VIN
		INNER JOIN  Vehicle.Models M ON V.ModelID = M.ModelID
		INNER JOIN  Vehicle.SubBrands SB ON M.SubBrandID = SB.SubBrandID
	--------------------------------------------------------------------------
	
	
	--------------------------------------------------------------------------
	-- Clear down Email Table
	TRUNCATE TABLE SelectionOutput.Email
	--------------------------------------------------------------------------


	------------------------------------------------------------------
	-- Update Email Contact Details 
	EXEC SelectionOutput.uspOnlineEmailContactDetails
	------------------------------------------------------------------
	

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