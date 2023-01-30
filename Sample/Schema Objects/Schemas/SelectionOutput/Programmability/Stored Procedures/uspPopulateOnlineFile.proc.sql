CREATE PROCEDURE [SelectionOutput].[uspPopulateOnlineFile]
@MarketISOAlpha3  VARCHAR(3)  
AS


/*
		Purpose:	Loads data from the email, postal and telephone tables into the table that gets outputted to online.  
	
		Version		Date				Developer			Comment
LIVE	1.0			$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspSELECTIONOUTPUT_JLR_All
LIVE	1.1			04/04/2012			Attila Kubanda		BUG 6558 RoadSide output has to have VIN in the columnlist.
LIVE	1.2			18/12/2012			Chris Ross			BUG 8135 Added extra fields in for output in On-line Selection Output
LIVE	1.3			10/01/2013			Chris Ross			BUG 8135 Add extra fields (for On-line output only)
LIVE	1.4			05/02/2013			Chris Ross			BUG 8499 Add OutletPartyID to On-line output.
LIVE	1.5			12/02/2013			Chris Ross			Add in SelectionOutputPassword
LIVE	1.6			16/04/2013			Martin Riverol		Added in Model Variant fields
LIVE	1.7			23/10/2013			Chris Ross			BUG 9460 Re-populate address where not present due to suppressions
LIVE	1.8			16/01/2014			Chris Ross			BUG 9500 Add in SMS output table.  Also update check on including
LIVE																 email to use ReoutputIndicator flag and new param @MarketISOAlpha3
LIVE	1.9			08/12/2014			Chris Ross			BUG 10916 Populate the 'blank' column with the Super-national region
LIVE				06/12/2014			Chris Ross						- above also required the removal of filter on ManufacturerDealerCode being present.
LIVE	1.10		26/02/2015			Chris Ross			BUG 11026 - Change "blank" column from SuperNationalRegion to BusinessRegion.
LIVE	1.11		21/04/2015			Peter Doyle			Code around NULL BusinessRegion trying to UPDATE "blank" column which doesn't allow nulls
LIVE	1.12		09/10/2015			Chris Ross			BUG 11387 - Add case statement on CATI to output 'C' as ITYPE, if from a Re-output.
LIVE	1.13		12/10/2015			Eddie Thomas		BUG 11844 Employee Reporting - Add Employee Name/Code to Online table
LIVE	1.14		09/11/2015			Eddie Thomas		BUg 11906 Model Summary for the Postal Team
LIVE	1.15		16/11/2015			Eddie Thomas		BUG 11387 - Add new field CAPIType and business logic to populate it
LIVE	1.16		15/01/2016			Eddie Thomas		BUG 12066 (SSA CATI) - At the request of production, rolled back change made in V 1.12
LIVE	1.17		31/03/2016			Chris Ross			BUG 12407 - Add the ITYPE Pilot code if one is present for the Market/Dealer/event category.
LIVE	1.18		12/09/2016			Chris Ross			BUG 12859 - Set ModelYear to zero for LostLeads.  
																	Also, fixed bug where Market not being populated for Re-Outputs
LIVE	1.19		12/10/2016			Chris Ledger		BUG 13098 - Fix bug which produces duplicates with 
LIVE	1.20		22/10/2016			Chris Ledger		BUG 13098 - Include ReoutputIndicator for SMS
LIVE	1.21		21/12/2016			Chris Ledger		BUG 13422 - Populate SampleFile field with PilotQuestionnaire code if present for Market/Dealer/Event Category
LIVE	1.22		16/01/2017			Chris Ledger		BUG 13422 - Change Update To Populate SampleFile field with PilotQuestionnaire code for Postal Output
LIVE	1.23		23/01/2017			Chris Ross			BUG 13646 - Add in ServiceAdvisorID, ServiceAdvisor, TechnicianID and TechnicianName columns from Event.AdditionalInfoSales
LIVE	1.24		31/01/2017			Chris Ross			BUG 13510 - Add in SalesAdvisorID and SalesAdvisor columns from Event.AdditionalInfoSales
LIVE	1.25		07/02/2017			Eddie Thomas		BUG 13525 - Added and populated Rockar questionnaire flag
LIVE	1.26		16/02/2017			Eddie Thomas		BUG 13466 - Flagging SVO Vehicles; Populate filed SVOvehicle
LIVE	1.27		22/03/2017			Eddie Thomas		BUG 13635 - When Market is Laos and the language is Laotian, Output teh Language of Thai instead
LIVE	1.28		27/03/2017			Chris Ledger		BUG 13670 - Add VistaContractOrderNumber, DealNo
LIVE	1.29		30/03/2017			Chris Ledger		BUG 13670 - Add FOBCode and US UnknownLang
LIVE	1.30		31/03/2017			Chris Ledger		BUG 13790 - Populate SampleFlag field with 3 for Canada/US Sales/Service
LIVE	1.31		04/04/2017			Chris Ledger		BUG 13670 - Add Canada UnknownLang
LIVE	1.32		07/04/2017			Chris Ledger		BUG 13670 - Optimise Update of US/Canada VistaContractOrderNumber, DealNo & UnknownLang
LIVE	1.33		11/04/2017			Eddie Thomas		BUG 13635 - Update the language code for Laos language Chinese for Dimensions.  ZHO --> CHT
LIVE	1.34		22/05/2017			Eddie Thomas		BUG 13894 - Contents of the Field CarReg is suppressed if the country is China
LIVE	1.35		25/05/2017			Chris Ledger		BUG 13904 - Update CustomerIdentifier for Russian Lost Leads 
LIVE	1.36		14/06/2017			Chris Ledger		BUG 14000 - Ensure UnknownLang and VistaContractOrderNumber only set for US
LIVE	1.37		27/06/2017			Chris Ledger		BUG 14053 - Undo Populate SampleFlag field with 3 for Canada/US Sales/Service
LIVE	1.38		04/07/2017			Chris Ledger		BUG 14019 - Use VIN 10th Character/BuildYear Combination for ModelYear 	
LIVE	1.39		16/10/2017			Chris Ross			BUG 14201 - Add 900,000,000 to the Model code where the Vehicle.Models AllowSVO column and the Vehicle.Vehicles SVOVehicle are both set TRUE.
LIVE	1.40		24/10/2017			Chris Ross			BUG 14245 - Populate Bilingual columns in On-line table from output type tables (SMS/Postal/Email - excludes CATI)
LIVE	1.41		09/11/2017			Chris Ledger		Further Optimisation to Stop Selection Output Suspending
LIVE	1.42		23/02/2018			Chris Ledger		BUG 14272 - Update CustomerIdentifier for USA Lost Leads
LIVE	1.43		20/03/2018			Chris Ross			BUG 14413 - Include all LostLead recs in CustomerID update.  Also, use the ParentAuditItemID from the AdditionalInfoSales to ensure we get the correct customer ID.
LIVE	1.44		29/03/2018			Chris Ledger		BUG 14640 - Set UnknownLang field to 1 for all Mauritius output.
LIVE	1.45		23/07/2018			Chris Ledger		BUG 14869 - Change LostLead to pick up 7 digit CustomerID (i.e. CustomerIdentifierUsable = 0)
LIVE	1.46		15/08/2018			Eddie Thomas		BUG 14797 - Portugal Roadside - Contact Methodology Change request - Populating expiration field in SelectionOutput.SMS
LIVE	1.47		25/09/2018			Eddie Thomas		BUG 14820 - Lost Leads -  Global loader change 
LIVE	1.48		03/09/2019			Chris Ledger		Only Run US Updates When Market = US
LIVE	1.49		03/09/2019			Chris Ledger		Only Run Canada Updates When Market = Canada
LIVE	1.50		28/10/2019			Chris Ledger		BUG 15490 - Add DealerType column
LIVE	1.51		14/11/2019			Chris Ledger		BUG 16691 - Add Postal ReOutput to Online file
LIVE	1.52		15/01/2019			Eddie Thomas		BUG 16850 - Addition of RONumber (UK Service Logistix Loaders)
LIVE	1.53		28/01/2020			Chris Ledger		BUG 16891 - Addition of ServiceEventType
LIVE	1.54		28/01/2020			Chris Ledger		BUG 16819 - Update Queue for Lost Leads
LIVE	1.55		12/03/2020			Ben King			BUG 18000 - Map Business Region to 'blank' variable.
LIVE	1.56		19/01/2021			Eddie Thomas		BUG 18082 - Add Dealer10DigitCode into Online output
LIVE	1.57		25/02/2021			Eddie Thomas		AZURE DEVOPS TASK 296 - Add EventID into SelectionOutput
LIVE	1.58		15/04/2021			Chris Ledger		TASK 388 - Update ServiceEventType from CRM Data
LIVE	1.59		15/04/2021			Chris Ledger		Fix Add Dealer10DigitCode
LIVE	1.60		29/04/2021			Chris Ledger		TASK 416 - Undo V1.39 Add 900,000,000 to the Model code where the Vehicle.Models AllowSVO column and the Vehicle.Vehicles SVOVehicle are both set TRUE
LIVE	1.61		10/06/2021			Eddie Thomas		Only carry out V1.58 if there are Service records in OnlineOutput table
LIVE	1.62    	11/06/2021		    Ben King		    TASK 499 - Changes to Language Codes
LIVE	1.63		29/06/2021			Eddie Thomas		BugTracker 18235: PHEV Flags
LIVE	1.64		06/08/2021			Eddie Thomas		BugTracker 18309: Bug fix Business region not populating for Korea CRC
LIVE	1.65		13/08/2021			Eddie Thomas		Bugtracker 18306 - If we have a company Name Only Output Company Name in the Fullname Column (Germany)
LIVE	1.66		10/09/2021			Chris Ledger		TASK 567 - Remove CustomerIdentifierUsable = 0 for LostLeads
LIVE	1.67		05/11/2021			Eddie Thomas		Bugtracker 18358: Ignore CustomerIdentifierUsable to force CustomerID population
LIVE	1.68		08/11/2021			Eddie Thomas		TASK 694 / Bugtracker 18394 - Use the FranchiseTradingTitle For Dealer name when Market is Taiwan
LIVE	1.69		13/01/2021			Chris Ledger		TASK 754 - Change mapping of Business Region to avoid CASE statement in JOIN
LIVE 	1.70		20/01/2022			Ben King			TASK 764 - 19437 - Taiwan is not a Province of China
LIVE 	1.71		02/02/2022			Chris Ledger		TASK 778 - 19445 - Fix bug with Taiwan Business Region mapping
LIVE	1.72		24/03/2022			Chris Ledger		Query Optimisation
LIVE	1.73		16/06/2022			Eddie Thomas		TASK 877 - Populate LandRoverExperienceID
LIVE	1.74		23/06/2022			Eddie Thomas		TASK 900 - Business & Fleet Vehicle, Populate BusinessFlag & CommonSaleType
LIVE	1.75		18/07/2022			Eddie Thomas		TASK 963 - EngineTypeID is populated via vehicle table
LIVE	1.76		07/09/2022			Eddie Thomas		TASK 1017 - HOB : Add Sub brand information
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

DECLARE @MarketName NVARCHAR(200) =''

SELECT DISTINCT @MarketName = Market 
FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
WHERE ISOAlpha3 = @MarketISOAlpha3


BEGIN TRY

	INSERT INTO SelectionOutput.OnlineOutput
	(
		[Password], 
		ID, 
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
		CATIType,
		[Queue],
		AssignedMode,
		RequiresManualDial,
		CallRecordingsCount,
		TimeZone,			
		CallOutcome,		
		PhoneNumber,		
		PhoneSource,		
		[Language],			
		ExpirationTime,	
		HomePhoneNumber,	
		WorkPhoneNumber,	
		MobilePhoneNumber,
		BilingualFlag,		-- V1.40	
		langBilingual,		-- V1.40
		DearNameBilingual	-- V1.40				
	)
	SELECT
		SO.[Password], 
		SO.ID, 
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
		SO.[week], 
		SO.test, 
		SO.SampleFlag, 
		SO.SalesServiceFile,
		'H' AS ITYPE,
		@MarketISOAlpha3 AS Market,				-- V1.18
		DATEADD(D, MaxDays.NumDaysToExpireOnlineQuestionnaire, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) AS Expired,
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
		0 AS CATIType,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,	
		SO.BilingualFlag,		-- V1.40	
		SO.langBilingual,		-- V1.40
		SO.DearNameBilingual	-- V1.40			
	FROM SelectionOutput.Email SO
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
		INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
		LEFT  JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
		LEFT JOIN (	SELECT BMQ.Brand, 
						BMQ.ISOAlpha3, 
						BMQ.Questionnaire, 
						MAX(BMQ.NumDaysToExpireOnlineQuestionnaire) AS NumDaysToExpireOnlineQuestionnaire -- V1.19
					FROM dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ 
					WHERE BMQ.NumDaysToExpireOnlineQuestionnaire IS NOT NULL
					GROUP BY BMQ.Brand, 
						BMQ.ISOAlpha3, 
						BMQ.Questionnaire) MaxDays ON MaxDays.Brand = SO.sType
													AND MaxDays.ISOAlpha3 = @MarketISOAlpha3
													AND MaxDays.Questionnaire = ET.EventCategory
    WHERE ISNULL(O.IncludeEmailOutputInAllFile, 0) = 1
		OR SO.ReoutputIndicator = 1								-- V1.8
	UNION
	SELECT
		SO.[Password], 
		SO.ID, 
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
		SO.[week], 
		SO.test, 
		SO.SampleFlag, 
		SO.SalesServiceFile,
		'' AS ITYPE,
		@MarketISOAlpha3 AS Market,					-- V1.18
		NULL AS Expired,
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
		0 AS CATIType,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,	
		SO.BilingualFlag,		-- V1.40	
		SO.langBilingual,		-- V1.40
		SO.DearNameBilingual	-- V1.40			
	FROM SelectionOutput.Postal SO
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
		INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
		LEFT JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
		--INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType	-- V1.19
		--															AND BMQ.ISOAlpha3 = O.Market
		--															AND BMQ.Questionnaire = ET.EventCategory
	WHERE O.IncludePostalOutputInAllFile = 1
		OR SO.ReoutputIndicator = 1								-- V1.51
	UNION
	SELECT													-- V1.8
		SO.[Password], 
		SO.ID, 
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
		SO.[week], 
		SO.test, 
		SO.SampleFlag, 
		SO.SalesServiceFile,
		'S' AS ITYPE,
		@MarketISOAlpha3 AS Market,					-- V1.18
		--NULL AS Expired,
		CASE	
			WHEN MaxDays.NumDaysToExpireOnlineQuestionnaire > 0 THEN DATEADD(D, MaxDays.NumDaysToExpireOnlineQuestionnaire, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0))
			ELSE NULL						-- V1.46
		END AS Expired,
		SO.EventDate,
		SO.DealerCode,
		SO.LandPhone,
		SO.WorkPhone,
		SO.MobilePhone,
		SO.PartyID,
		SO.GDDDealerCode,
		SO.ReportingDealerPartyID,
		SO.VariantID,
		SO.ModelVariant,
		0 AS CATIType,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		SO.BilingualFlag,		-- V1.40	
		SO.langBilingual,		-- V1.40
		SO.DearNameBilingual	-- V1.40					
	FROM SelectionOutput.SMS SO
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
		INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
		LEFT JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf		-- V1.20
		-- V1.46
		LEFT JOIN (	SELECT BMQ.Brand, 
						BMQ.ISOAlpha3, 
						BMQ.Questionnaire, 
						MAX(BMQ.NumDaysToExpireOnlineQuestionnaire) AS NumDaysToExpireOnlineQuestionnaire
					FROM dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ 
					WHERE BMQ.NumDaysToExpireOnlineQuestionnaire IS NOT NULL
						AND ContactMethodologyTypeID = 8		--'Mixed (SMS & Email)'	 
					GROUP BY BMQ.Brand, 
						BMQ.ISOAlpha3, 
						BMQ.Questionnaire
				HAVING MAX(BMQ.NumDaysToExpireOnlineQuestionnaire) > 0 ) MaxDays ON MaxDays.Brand = SO.sType 
																					AND MaxDays.ISOAlpha3 = @MarketISOAlpha3 
																					AND MaxDays.Questionnaire = ET.EventCategory
	-- V1.46							
	WHERE O.IncludeSMSOutputInAllFile = 1
		-- V1.18  -- SMS re-outputs should be in On-line but will need to be picked up as part of Korea new SMS + Email contact methodology bug 13098
		OR SO.ReoutputIndicator = 1								-- V1.20
	UNION
	SELECT
		SO.[Password], 
		SO.ID, 
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
		SO.[week], 
		SO.test, 
		SO.SampleFlag, 
		SO.SalesServiceFile,
		--CASE WHEN ISNULL(SO.ReOutputFlag, 0) = 1 THEN 'C' ELSE 'T' END AS ITYPE,					---- V1.12
		'T' AS ITYPE,
		@MarketISOAlpha3 AS Market,					-- V1.18
		-- V1.18 -- @MarketName, 
		NULL AS Expired,
		SO.EventDate,
		SO.DealerCode,
		SO.LandPhone,
		SO.WorkPhone,
		SO.MobilePhone,
		SO.PartyID,
		SO.GDDDealerCode,
		SO.ReportingDealerPartyID,
		SO.VariantID,
		SO.ModelVariant,
		CASE
			 WHEN OL.CaseID IS NULL THEN 3								-- CATI only	V1.15
			 WHEN OC.OutcomeCodeTypeID IS NOT NULL THEN 2				-- Bounceback	V1.15
			 WHEN EC.CaseID IS NOT NULL THEN 1							-- NonResponder	V1.15
		END AS CATIType,
		[Queue],
		AssignedMode,
		RequiresManualDial,
		CallRecordingsCount,
		TimeZone,			
		CallOutcome,		
		PhoneNumber,		
		PhoneSource,		
		[Language],			
		ExpirationTime,	
		HomePhoneNumber,	
		WorkPhoneNumber,	
		MobilePhoneNumber,		
		NULL,		-- V1.40
		NULL,		-- V1.40
		NULL		-- V1.40		
	FROM SelectionOutput.vwCATI SO
		LEFT JOIN SelectionOutput.Email E ON E.ID = SO.ID
		LEFT JOIN SelectionOutput.Postal P ON P.ID = SO.ID
		INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
		INNER JOIN Event.Events EV ON EV.EventID = AEBI.EventID
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = EV.EventTypeID
		LEFT JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
		--INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType	-- V1.19
		--															AND BMQ.ISOAlpha3 = O.Market
		--															AND BMQ.Questionnaire = ET.EventCategory
		--Previously selected for email															
		LEFT JOIN (	SELECT CaseID 
					FROM Event.CaseOutput
					WHERE  CaseOutputTypeID = (	SELECT CaseOutputTypeID 
												FROM [Event].CaseOutputTypes 
												WHERE CaseOutputType ='Online') ) OL ON SO.ID = OL.CaseID															
		--BounceBack info
		LEFT JOIN [Event].CaseContactMechanismOutcomes CCO ON SO.ID = CCO.CaseID
		LEFT JOIN [Sample].ContactMechanism.OutcomeCodes OC ON CCO.OutcomeCode = OC.OutcomeCode 
																AND OC.OutcomeCode IN (10, 20, 21, 22, 23, 30, 50, 51, 52, 53, 54, 99)
		--Non responder
		LEFT JOIN [Event].Cases EC ON SO.ID = EC.CaseID 
											AND EC.OnlineExpirydate <= GETDATE() 
											AND EC.ClosureDate IS NULL
											AND EC.CaseStatusTypeID = 1																
	WHERE (O.IncludeCATIOutputInAllFile = 1 OR SO.ReOutputFlag = 1) 
		AND E.ID IS NULL 
		AND P.ID IS NULL


	-- WE DON'T OUTPUT THE EMAIL DATA SEPARATELY SO WE CAN REMOVE THAT NOW
	DELETE FROM SelectionOutput.Email


	-- Add in additional information required for On-line    -- V1.3
	UPDATE O
	SET ManufacturerDealerCode = F.ManufacturerDealerCode, 
		ModelYear = CASE	WHEN EC.EventCategory IN ('LostLeads', 'PreOwned LostLeads') THEN 0						-- V1.50
							ELSE CASE	WHEN ABS(ISNULL(MY.ModelYear,0) - ISNULL(V.BuildYear,0)) <= 1 THEN MY.ModelYear
										ELSE V.BuildYear END 
					END,							-- V1.38
		CustomerIdentifier = CR.CustomerIdentifier, 
		OwnershipCycle  = CD.OwnershipCycle,
		OutletPartyID = CD.DealerPartyID,					-- V1.4
		blank = ISNULL(F.BusinessRegion,''),				-- V1.10
		PilotCode = ISNULL(DOC.PilotCodeForITYPE, '')		-- V1.17
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = O.id
		INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = etype 
		INNER JOIN Event.EventCategories EC ON ETC.EventCategoryID = EC.EventCategoryID
		LEFT JOIN SelectionOutput.DealerPilotOutputCodes DOC ON DOC.DealerCode = O.DealerCode			-- V1.17
															AND DOC.Market = O.Market
															AND DOC.EventCategory = EC.EventCategory
															AND DOC.BaseITYPE = O.ITYPE					
		LEFT JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Flat F	ON F.DealerCode = O.DealerCode
																		AND F.OutletPartyID = CD.DealerPartyID 
																		AND F.OutletFunction = CASE EC.EventCategory	WHEN 'Service' THEN 'Aftersales'
																														ELSE EC.EventCategory END
																		--	AND F.ManufacturerDealerCode IS NOT NULL   -- V1.9
		LEFT JOIN [Vehicle].Vehicles V ON CD.VehicleID = V.VehicleID	-- V1.38
		LEFT JOIN [Vehicle].ModelYear MY ON MY.VINCharacter = SUBSTRING(O.VIN , MY.VINPosition , 1) AND CD.ManufacturerPartyID = MY.ManufacturerPartyID
		LEFT JOIN [$(AuditDB)].[Audit].CustomerRelationships CR ON CR.PartyIDFrom = CD.PartyID 
																--AND CR.CustomerIdentifierUsable = 1		-- V1.67
																AND CR.AuditItemID = (	SELECT MAX(AuditItemID) 
																						FROM [$(AuditDB)].[Audit].CustomerRelationships CR2 
																						WHERE CR2.PartyIDFrom = CR.PartyIDFrom 
																							AND CR2.CustomerIdentifierUsable = CR.CustomerIdentifierUsable)
	
	
	
	------------------------------------------------------------------------------
	-- V1.69 UPDATE BusinessRegion for All other questionnaires not within Dealer Hierarchy.
	-- NB: BusinessRegion is unique to Market
	------------------------------------------------------------------------------
	UPDATE O
	SET O.blank = ISNULL(D.BusinessRegion,'')
	FROM SelectionOutput.OnlineOutput O
		--INNER JOIN ContactMechanism.Countries C ON O.CTRY = C.Country
		INNER JOIN dbo.Markets M ON O.ccode = M.CountryID											-- V1.71
		INNER JOIN dbo.DW_JLRCSPDealers D ON D.Market = COALESCE(M.DealerTableEquivMarket, M.Market)
											AND D.ThroughDate IS NULL
	WHERE ISNULL(O.blank,'') = ''
	------------------------------------------------------------------------------


	------------------------------------------------------------------------------
	-- V1.37 V1.30 UPDATE SampleFlag to 3 for US/Canada Sales/Service
	------------------------------------------------------------------------------
	--UPDATE O
	--SET O.SampleFlag = 3
	--FROM SelectionOutput.OnlineOutput O
	--	INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = O.etype 
	--	INNER JOIN Event.EventCategories EC ON ETC.EventCategoryID = EC.EventCategoryID
	--WHERE O.Market IN ('CAN','USA')
	--	AND EC.EventCategory IN ('Sales','Service')
	------------------------------------------------------------------------------
	

	-- Where no address is present, this may be because of suppressions.			V1.7
	-- As the address is required by EventX we need to add it back in again to the on-line output 
	;WITH CTE_Addresses (PartyID, ContactMechanismID) AS 
	(
		SELECT O.PartyID, 
			MAX(PA.ContactMechanismID) AS ContactMechanismID
		FROM SelectionOutput.OnlineOutput O
			INNER JOIN ContactMechanism.PartyContactMechanisms P ON P.PartyID = O.PartyID
			INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = P.ContactMechanismID
		WHERE ISNULL(O.Add3, '') = ''
		GROUP BY O.PartyID
	)
	UPDATE O 
	SET	Add1 = PA.BuildingName,
		Add2 = PA.SubStreet,
		Add3 = PA.Street,
		Add4 = PA.SubLocality,
		Add5 = PA.Locality,
		Add6 = PA.Town,
		Add7 = PA.Region,
		Add8 = PA.PostCode,
		Add9 = '',
		CTRY = C.Country
	FROM CTE_Addresses CE
		INNER JOIN SelectionOutput.OnlineOutput O ON CE.PartyID = O.PartyID
		INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = CE.ContactMechanismID
		LEFT JOIN ContactMechanism.Countries C ON C.CountryID = PA.CountryID
	
	
	-- V1.13
	-- SELECT AI.EventID, AI.Salesman, AI.SalesmanCode
	UPDATE OO
	SET	EmployeeName = AI.Salesman,
		EmployeeCode = AI.SalesmanCode,
		ServiceAdvisorID = AI.ServiceAdvisorID,				-- V1.23
		ServiceAdvisorName = AI.ServiceAdvisorName,			-- V1.23
		TechnicianID = AI.TechnicianID,						-- V1.23
		TechnicianName = AI.TechnicianName,					-- V1.23
		SalesAdvisorID = AI.SalesAdvisorID,					-- V1.24
		SalesAdvisorName = AI.SalesAdvisorName,				-- V1.24
		RepairOrderNumber = AI.RONumber,					-- V1.52
		ServiceEventType = AI.JLRSuppliedEventType			-- V1.53

	FROM [Event].AdditionalInfoSales AI
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AI.EventID = AEBI.EventID     
		INNER JOIN  SelectionOutput.OnlineOutput OO ON AEBI.CaseID = OO.ID 
	WHERE ISNULL(RepairOrderNumber,'') =''							-- V1.52 MAKE SURE WE DON'T OVERWRITE REPAIR ORDER NUMBER (SEE V1.32 Updates)


	UPDATE SelectionOutput.OnlineOutput
	SET ModelSummary = CASE	WHEN FullModel LIKE '%S-TYPE%' THEN 'S-TYPE'
							WHEN FullModel LIKE '%XJ%' THEN 'XJ'
							WHEN FullModel LIKE '%XK%' THEN 'XK'
							WHEN FullModel LIKE '%X-TYPE%' THEN 'X-TYPE'
							WHEN FullModel LIKE '%XF Sportbrake%' THEN 'XF Sportbrake'
							WHEN FullModel LIKE '%XF%' THEN 'XF'
							WHEN FullModel LIKE '%F-TYPE%' THEN 'F-TYPE'
							WHEN FullModel LIKE '%XE%' THEN 'XE'
							WHEN FullModel LIKE '%Defender%' THEN 'Defender'
							WHEN FullModel LIKE '%Freelander%' THEN 'Freelander'
							WHEN FullModel LIKE '%Range Rover Evoque%' THEN 'Range Rover Evoque'
							WHEN FullModel LIKE '%Range Rover Sport%' THEN 'Range Rover Sport'
							WHEN FullModel LIKE '%Range Rover%' THEN 'Range Rover'
							WHEN FullModel LIKE '%Discovery Sport%' THEN 'Discovery Sport'
							WHEN FullModel LIKE '%Discovery%' THEN 'Discovery'
							WHEN FullModel LIKE '%F-PACE%' THEN 'F-PACE'
							ELSE FullModel END
	

	-- V1.25
	UPDATE OO
	SET	RockarDealer = D.RockarDealer
	FROM SelectionOutput.OnlineOutput OO
		INNER JOIN dbo.DW_JLRCSPDealers D ON oo.OutletPartyID = D.OutletPartyID

	
	------------------------------------------------
	-- V1.26 
	-- SVO / SVO Bespoke vehicle and dealer flagging
	------------------------------------------------
	UPDATE		OO
	SET			SVOvehicle	= ISNULL(VEH.SVOTypeID,0),
				FOBCode		= VEH.FOBCode,				-- V1.29
				SubBrand	= SB.SubBrand				-- V1.76
	FROM		SelectionOutput.OnlineOutput	OO
	INNER JOIN	Vehicle.Vehicles				VEH ON OO.VIN = VEH.VIN
	INNER JOIN  Vehicle.Models					MD ON VEH.ModelID = MD.ModelID			--V1.76
	INNER JOIN  Vehicle.SubBrands				SB ON MD.SubBrandID = SB.SubBrandID		--V1.76

	UPDATE O
	SET SVODealer = 1 
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN [Event].vwEventTypes ET ON O.etype = ET.EventTypeID 
												AND ET.EventCategory IN ('Sales','Service')
		INNER JOIN [$(ETLDB)].dbo.SVOTypes SVO ON O.SVOvehicle = SVO.SVOTypeID
		INNER JOIN dbo.Languages LNG ON O.Lang = LanguageID
	WHERE SVODescription IN ('SVO Bespoke','Bespoke')  
		AND ITYPE ='H'
		AND LNG.[Language] IN ('English','American English (USA & Canada)')


	/* V1.60 Undo V1.39
	-- Update the Model Code for SVO flagged vehicles where the AllowSVO model flag is set        -- V1.39 
	;WITH CTE_SVO_ModelCases AS 
	(
		SELECT DISTINCT OO.ID 	
		FROM SelectionOutput.OnlineOutput OO
			INNER JOIN Vehicle.Vehicles VEH ON OO.VIN = VEH.VIN
			LEFT JOIN Vehicle.Models M ON M.ModelID = VEH.ModelID		-- V1.39
		WHERE OO.SVOvehicle <> 0 
			AND ISNULL(M.AllowSVO, 0) = 1 
			AND OO.ModelCode < 900000000  -- Ensure we only add once
	)
	UPDATE OO
	SET OO.modelcode = OO.ModelCode + 900000000 
	FROM CTE_SVO_ModelCases MC
		INNER JOIN SelectionOutput.OnlineOutput OO ON OO.ID = MC.ID
	*/	
	

	------------------------------------------------
	-- V1.27 
	-- LAOS CATI language remapping
	------------------------------------------------
	UPDATE O
	SET O.Fullname = CASE	WHEN O.Market ='LAO' And CD.LanguageID =269 THEN Party.udfGetAddressingText(O.PartyID, CD.QuestionnaireRequirementID, O.Ccode, COALESCE(Q.CATILanguageID,CD.LanguageID), (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')) 
							ELSE Party.udfGetAddressingText(O.PartyID, CD.QuestionnaireRequirementID, O.Ccode, CD.LanguageID, (	SELECT AddressingTypeID 
																																FROM Party.AddressingTypes 
																																WHERE AddressingType = 'Addressing')) END,
		O.DearName = CASE	WHEN O.Market ='LAO' And CD.LanguageID =269 THEN Party.udfGetAddressingText(O.PartyID, CD.QuestionnaireRequirementID, O.Ccode, COALESCE(Q.CATILanguageID,CD.LanguageID), (SELECT AddressingTypeID FROM Party.AddressingTypes WHERE AddressingType = 'Addressing')) 
							ELSE Party.udfGetAddressingText(O.PartyID, CD.QuestionnaireRequirementID, O.Ccode, CD.LanguageID, (	SELECT AddressingTypeID 
																																FROM Party.AddressingTypes 
																																WHERE AddressingType = 'Salutation')) END,
		O.lang = CASE	WHEN O.Market ='LAO' AND CD.LanguageID =269 THEN COALESCE(Q.CATILanguageID,CD.LanguageID)
						ELSE CD.LanguageID END, 
		[Language] = CASE	WHEN O.Market ='LAO' And CD.LanguageID =269 THEN LNG.[ISOAlpha3]		-- V1.33
							ELSE O.[Language] END													-- V1.33
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Meta.CaseDetails CD ON O.ID = CD.CaseID 
		INNER JOIN Requirement.QuestionnaireRequirements Q ON CD.QuestionnaireRequirementID = Q.RequirementID
		INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata MD ON Q.RequirementID = MD.QuestionnaireRequirementID 
		INNER JOIN dbo.Languages LNG ON CASE	WHEN O.Market ='LAO' And CD.LanguageID =269 THEN COALESCE(Q.CATILanguageID,CD.LanguageID)
												ELSE CD.LanguageID 
										END = LNG.LanguageID
	WHERE O.Market ='LAO' 
		AND IType ='T'


	------------------------------------------------
	-- V1.32 Update US VistaContractOrderNumber & UnknownLang
	------------------------------------------------
	IF @MarketName = 'United States of America'		-- V1.48
		BEGIN
			
			DROP TABLE IF EXISTS #Vista_Contract_Sales

			CREATE TABLE #Vista_Contract_Sales
			(	
				RowID INT,
				CaseID INT,
				VistaContractOrderNumber VARCHAR(100),
				UnknownLang VARCHAR(100)
			);
		
			INSERT INTO #Vista_Contract_Sales (RowID, CaseID, VistaContractOrderNumber, UnknownLang)
			SELECT ROW_NUMBER() OVER (PARTITION BY SL.CaseID ORDER BY SL.AuditItemID DESC) AS RowID, 
				SL.CaseID,
				S.VISTACONTRACT_COMMON_ORDER_NUM AS VistaContractOrderNumber,
				CASE	WHEN NULLIF(S.ACCT_PREF_LANGUAGE_CODE,'') IS NULL THEN 1 
						ELSE 0 END AS UnknownLang    
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype 
													AND ET.EventCategory = 'Sales'
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
				INNER JOIN [$(ETLDB)].CRM.Vista_Contract_Sales S ON SL.AuditItemID = S.AuditItemID
			WHERE SL.Market = 'United States of America'			-- V1.36
			OPTION (MAXDOP 1);										-- V1.41

			UPDATE O 
			SET O.VistaContractOrderNumber = VCS.VistaContractOrderNumber, 
				O.UnknownLang = VCS.UnknownLang
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN #Vista_Contract_Sales VCS ON O.ID = VCS.CaseID
			WHERE VCS.RowID = 1
		
		END
	------------------------------------------------


	------------------------------------------------
	-- V1.32 Update Canada DealNo & UnknownLang
	------------------------------------------------
	IF @MarketName = 'Canada'				-- V1.49
		BEGIN
			
			DROP TABLE IF EXISTS #CanadaSales

			CREATE TABLE #CanadaSales
			(	
				RowID INT,
				CaseID INT,
				DealNo VARCHAR(100),
				UnknownLang VARCHAR(100)
			);
		
			INSERT INTO #CanadaSales (RowID, CaseID, DealNo, UnknownLang)
			SELECT ROW_NUMBER() OVER (PARTITION BY SL.CaseID ORDER BY SL.AuditID DESC, SL.PhysicalFileRow DESC) AS RowID, 
				SL.CaseID,
				S.DealNumber AS DealNo,
				CASE	WHEN NULLIF(S.Language,'') IS NULL THEN 1 
						ELSE 0 END AS UnknownLang    
			FROM SelectionOutput.OnlineOutput AS O
				INNER JOIN [Event].vwEventTypes AS ET ON ET.EventTypeID = O.etype 
														AND ET.EventCategory = 'Sales'
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
				INNER JOIN [$(ETLDB)].Canada.Sales S ON SL.AuditID = S.AuditID 
														AND SL.PhysicalFileRow = S.PhysicalRowID
			OPTION (MAXDOP 1);										-- V1.41
 
			UPDATE O 
			SET O.DealNo = CS.DealNo, 
				O.UnknownLang = CS.UnknownLang
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN #CanadaSales CS ON O.ID = CS.CaseID
			WHERE CS.RowID = 1
		
		END
	------------------------------------------------


	------------------------------------------------
	-- V1.32 Update US RepairOrderNumber & UnknownLang 
	------------------------------------------------
	IF @MarketName = 'United States of America'		-- V1.48
		BEGIN

			DROP TABLE IF EXISTS #DMS_Repair_Service

			CREATE TABLE #DMS_Repair_Service
			(	
				RowID INT,
				CaseID INT,
				RepairOrderNumber VARCHAR(100),
				UnknownLang VARCHAR(100)
			);
		
			INSERT INTO #DMS_Repair_Service (RowID, CaseID, RepairOrderNumber, UnknownLang)
			SELECT ROW_NUMBER() OVER (PARTITION BY SL.CaseID ORDER BY SL.AuditItemID DESC) AS RowID, 
				SL.CaseID,
				S.DMS_REPAIR_ORDER_NUMBER AS RepairOrderNumber,
				CASE	WHEN NULLIF(S.ACCT_PREF_LANGUAGE_CODE,'') IS NULL THEN 1 
						ELSE 0 END AS UnknownLang    
			FROM SelectionOutput.OnlineOutput O
			--	INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype									-- V1.72
			--									AND ET.EventCategory = 'Service'								-- V1.72
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON O.ID = SL.CaseID	-- V1.72
				INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service S ON SL.AuditItemID = S.AuditItemID
			WHERE SL.Market = 'United States of America'		-- V1.41
 			--OPTION (MAXDOP 1);								-- V1.41, V1.72

			UPDATE O 
			SET O.RepairOrderNumber = DRS.RepairOrderNumber, 
				O.UnknownLang = DRS.UnknownLang
			FROM SelectionOutput.OnlineOutput O
			INNER JOIN #DMS_Repair_Service DRS ON O.ID = DRS.CaseID
			WHERE DRS.RowID = 1
		END
	------------------------------------------------


	------------------------------------------------
	-- V1.32 Update Canada RepairOrderNumber & UnknownLang 
	------------------------------------------------
	IF @MarketName = 'Canada'				-- V1.49
		BEGIN
			
			DROP TABLE IF EXISTS #CanadaService

			CREATE TABLE #CanadaService
			(	
				RowID INT,
				CaseID INT,
				RepairOrderNumber VARCHAR(100),
				UnknownLang VARCHAR(100)
			);
		
			INSERT INTO #CanadaService (RowID, CaseID, RepairOrderNumber, UnknownLang)
			SELECT ROW_NUMBER() OVER (PARTITION BY SL.CaseID ORDER BY SL.AuditID DESC, SL.PhysicalFileRow DESC) AS RowID, 
				SL.CaseID,
				S.RO_NUM AS RepairOrderNumber,
				CASE	WHEN NULLIF(S.Language,'') IS NULL THEN 1 
						ELSE 0 END AS UnknownLang    
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype 
												AND ET.EventCategory = 'Service'
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
				INNER JOIN [$(ETLDB)].[Canada].[Service] S ON SL.AuditID = S.AuditID 
															AND SL.PhysicalFileRow = S.PhysicalRowID
 			OPTION (MAXDOP 1);									-- V1.41

			UPDATE O 
			SET O.RepairOrderNumber = CS.RepairOrderNumber, 
				O.UnknownLang = CS.UnknownLang
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN #CanadaService CS ON O.ID = CS.CaseID
			WHERE CS.RowID = 1
		END
	------------------------------------------------


	-- V1.34
	UPDATE O
	SET O.CarReg = ''
	FROM SelectionOutput.OnlineOutput O
	INNER JOIN Contactmechanism.Countries CN ON ISNULL(CCode,0) = CN.CountryID	
	WHERE CN.Country = 'China'
	
	
	---------------------------------------------------------------------
	-- Add in CustomerIdentifier for LostLeads		-- V1.35 V1.42 V1.43 V1.50 
	---------------------------------------------------------------------

	-- Populate CustomerID using ParentAuditItemID (used to set LostLead primary record which sets single Model, CreationDate, ETC on dupe rows)
	UPDATE O
	SET	CustomerIdentifier = CR.CustomerIdentifier,		-- Will be set NULL if ParentAuditItemID is not populated on AdditionalInfoSales 
		Queue = 'FRESH'									-- V1.54
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = O.id
		LEFT JOIN [Event].AdditionalInfoSales AIS ON AIS.EventID = CD.EventID 
													AND AIS.ParentAuditItemID IS NOT NULL
		LEFT JOIN [$(AuditDB)].[Audit].CustomerRelationships CR ON CR.AuditItemID = AIS.ParentAuditItemID 
																--AND CR.CustomerIdentifierUsable = 0		-- V1.45	-- V1.66
	WHERE CD.EventType IN ('LostLeads','PreOwned LostLeads')												-- V1.50
	
	-- Update using original method for historical data i.e. not able to populate via ParentAuditItemID on AdditionalInfoSales table
	UPDATE O
	SET	CustomerIdentifier = CR.CustomerIdentifier
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Meta.CaseDetails CD ON CD.CaseID = O.id
		LEFT JOIN [$(AuditDB)].[Audit].CustomerRelationships CR ON CR.PartyIDFrom = CD.PartyID 
																	AND CR.CustomerIdentifierUsable = 0				-- V1.45
																	AND CR.AuditItemID = (	SELECT MAX(AuditItemID) 
																							FROM [$(AuditDB)].[Audit].CustomerRelationships CR2 
																							WHERE CR2.PartyIDFrom = CR.PartyIDFrom 
																								AND CR2.CustomerIdentifierUsable = CR.CustomerIdentifierUsable)
	WHERE O.CustomerIdentifier IS NULL
		AND CD.EventType IN ('LostLeads','PreOwned LostLeads')														-- V1.50
	---------------------------------------------------------------------
	

	---------------------------------------------------------------------
	-- V1.44 UPDATE MAURITIUS UnknownLang
	---------------------------------------------------------------------
	UPDATE O SET O.UnknownLang = 1
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN ContactMechanism.Countries C ON ISNULL(O.ccode,0) = C.CountryID
	WHERE C.Country = 'Mauritius'
	---------------------------------------------------------------------	
	
	
	---------------------------------------------------------------------
	-- V1.47 UPDATE ADDITIONAL LOST LEADS FIELDS
	---------------------------------------------------------------------
	UPDATE OO
	SET JLREventType = AI.JLRSuppliedEventType,
		DateOfLeadCreation = AI.LostLead_DateOfLeadCreation,		
		CompleteSuppressionJLR = AI.LostLead_CompleteSuppressionJLR,		
		CompleteSuppressionRetailer	= AI.LostLead_CompleteSuppressionRetailer,		
		PermissionToEmailJLR = AI.LostLead_PermissionToEmailJLR,	
		PermissionToEmailRetailer = AI.LostLead_PermissionToEmailRetailer,	
		PermissionToPhoneJLR = AI.LostLead_PermissionToPhoneJLR,		
		PermissionToPhoneRetailer = AI.LostLead_PermissionToPhoneRetailer,		
		PermissionToPostJLR	= AI.LostLead_PermissionToPostJLR,		
		PermissionToPostRetailer = AI.LostLead_PermissionToPostRetailer,		
		PermissionToSMSJLR = AI.LostLead_PermissionToSMSJLR,		
		PermissionToSMSRetailer = AI.LostLead_PermissionToSMSRetailer,		
		PermissionToSocialMediaJLR = AI.LostLead_PermissionToSocialMediaJLR,		
		PermissionToSocialMediaRetailer = AI.LostLead_PermissionToSocialMediaRetailer,	
		DateOfLastContact = AI.LostLead_DateOfLastContact,
		LandRoverExperienceID = AI.LandRoverExperienceID,	-- V1.73
		BusinessFlag =	CASE 
								WHEN AI.CommonSaleType IN ('Fleet of 1-4 vehicles','Fleet of 5-24 vehicles','Fleet of 100+ vehicles') THEN 'YES'	-- V1.74
								WHEN AI.CommonSaleType IN ('Private Individual','Individual') THEN 'NO'
								ELSE ''											-- V1.74
						END,
		CommonSaleType =CASE
								WHEN AI.CommonSaleType = 'Fleet of 1-4 Vehicles'	THEN '1'		-- V1.74
								WHEN AI.CommonSaleType = 'Fleet of 5-24 Vehicles'	THEN '2'		-- V1.74
								WHEN AI.CommonSaleType = 'Fleet of 25-99 Vehicles'	THEN '3'		-- V1.74
								WHEN AI.CommonSaleType = 'Fleet of 100+ Vehicles'	THEN '4'		-- V1.74
								ELSE ''
						END
	FROM [Event].AdditionalInfoSales AI
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AI.EventID = AEBI.EventID     
		INNER JOIN SelectionOutput.OnlineOutput OO ON AEBI.CaseID = OO.ID 


	---------------------------------------------------------------------
	-- V1.50 UPDATE LOST LEADS DEALERTYPE
	---------------------------------------------------------------------
	UPDATE O
	SET O.DealerType = CASE	WHEN ET.EventCategory = 'PreOwned LostLeads' THEN 'PreOwned'
							ELSE 'Sales' END								
	FROM SelectionOutput.OnlineOutput O
	INNER JOIN	[Event].vwEventTypes ET ON O.etype = ET.EventTypeID 
	WHERE ET.EventCategory IN ('LostLeads','PreOwned LostLeads')

	
	---------------------------------------------------------------------
	-- V1.56 Add Dealer10DigitCode
	---------------------------------------------------------------------

	--DEALERS INFO
	;WITH Dealers_CTE (OutletPartyID, Brand, Market, Questionnaire, EventTypeID, Dealer10DigitCode) AS
	(
		SELECT DISTINCT 
			D.OutletPartyID, 
			D.Manufacturer, 
			D.Market, 
			D.OutletFunction, 
			ET.EventTypeID, 
			D.Dealer10DigitCode 
		FROM dbo.DW_JLRCSPDealers D
			INNER JOIN [Event].EventTypes ET ON  D.OutletFunctionID = ET.RelatedOutletFunctionID	-- V1.59
	)
	UPDATE O
	SET O.Dealer10DigitCode = CTE.Dealer10DigitCode
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN	Dealers_CTE CTE ON O.etype = CTE.EventTypeID 
										AND O.OutletPartyID = CTE.OutletPartyID


	---------------------------------------------------------------------
	-- V1.57 Add EventID
	---------------------------------------------------------------------
	UPDATE O
	SET O.EventID = CD.EventID
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN	Meta.CaseDetails CD ON O.ID = CD.CaseID

	


	--V1.61
	IF EXISTS (
				SELECT ID	FROM SelectionOutput.OnlineOutput O
				INNER JOIN	[Event].vwEventTypes ET ON ET.EventTypeID = O.etype AND ET.EventCategory = 'Service'
			  )
	BEGIN
			------------------------------------------------
			-- V1.58 Update ServiceEventType from CRM Data 
			------------------------------------------------
	
			DROP TABLE IF EXISTS #DMS_EVENT_TYPE
	
			CREATE TABLE #DMS_EVENT_TYPE
			(	
				RowID INT,
				CaseID INT,
				DMS_EVENT_TYPE VARCHAR(15)
			)
		
			INSERT INTO #DMS_EVENT_TYPE (RowID, CaseID, DMS_EVENT_TYPE)
			SELECT ROW_NUMBER() OVER (PARTITION BY SL.CaseID ORDER BY SL.AuditItemID DESC) AS RowID, 
				SL.CaseID,
				S.DMS_EVENT_TYPE
			FROM SelectionOutput.OnlineOutput O
				--INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype		-- V1.72
				--									AND ET.EventCategory = 'Service'	-- V1.72
				INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.CaseID = O.ID
				INNER JOIN [$(ETLDB)].CRM.DMS_Repair_Service S ON SL.AuditItemID = S.AuditItemID
			--OPTION (MAXDOP 1);									-- V1.41, V1.72

			UPDATE O SET O.ServiceEventType = DRS.DMS_EVENT_TYPE
			FROM SelectionOutput.OnlineOutput O
				INNER JOIN #DMS_EVENT_TYPE DRS ON O.ID = DRS.CaseID
			WHERE DRS.RowID = 1
			------------------------------------------------
	END

	------------------------------------------------------------
	----V1.62 -- CHANGE LANGUAGE CODE VARIATIONS
	UPDATE OO
	SET OO.Lang = CASE
							WHEN OO.CTRY = 'Brazil' AND OO.Lang = 375 THEN 375
							WHEN OO.CTRY = 'Portugal' AND OO.Lang = 375 THEN 20
							WHEN OO.CTRY = 'Spain' AND OO.Lang = 447 THEN 447
							WHEN OO.CTRY = 'Mexico' AND OO.Lang = 447 THEN 17
							ELSE OO.Lang -- APPLY PREFERRED LANGUAGE
						END						
	FROM SelectionOutput.OnlineOutput OO
	WHERE OO.CTRY IN ('Mexico','Portugal','Spain','Brazil')

	------------------------------------------------------------

	------V1.63 Populate Engine Type
	--UPDATE		OO
	--SET			OO.EngineType =		 1  --BEV
	--FROM		SelectionOutput.OnlineOutput	OO
	--INNER JOIN	Vehicle.ModelVariants			mv ON oo.VariantID = mv.VariantID
	--INNER JOIN	Vehicle.PHEVModels				ph ON mv.ModelID =	ph.ModelID	
	--WHERE		(LEFT(oo.VIN,4)				= ph.VINPrefix) AND 
	--			(SUBSTRING(oo.VIN, 8, 1)	= PH.VINCharacter) AND 
	--			(ph.EngineDescription Like '%BEV%') AND
	--			(OO.EngineType IS NULL) 


	--UPDATE		OO
	--SET			OO.EngineType =		 2  --PHEV
	--FROM		SelectionOutput.OnlineOutput	OO
	--INNER JOIN	Vehicle.ModelVariants			mv ON oo.VariantID = mv.VariantID
	--INNER JOIN	Vehicle.PHEVModels				ph ON mv.ModelID =	ph.ModelID	
	--WHERE		(LEFT(oo.VIN,4)				= ph.VINPrefix) AND 
	--			(SUBSTRING(oo.VIN, 8, 1)	= PH.VINCharacter) AND 
	--			(ph.EngineDescription Like '%PHEV%') AND
	--			(OO.EngineType IS NULL) 

	--V1.75
	UPDATE		OO
	SET			EngineType = VEH.EngineTypeID
	FROM		SelectionOutput.OnlineOutput	OO
	INNER JOIN	Meta.CaseDetails CD ON OO.ID = CD.CaseID
	INNER JOIN	Vehicle.Vehicles VEH ON CD.VehicleID =VEH.VehicleID

	--V1.75
	UPDATE	SelectionOutput.OnlineOutput
	SET		EngineType =0
	WHERE	EngineType IS NULL AND
			FullModel <> 'Unknown Vehicle'

	--V1.65
	UPDATE		OO
	SET			Fullname = ORG.OrganisationName 
	FROM		SelectionOutput.OnlineOutput OO
	INNER JOIN	Party.Organisations ORG ON OO.PartyID = ORG.PartyID
	INNER JOIN	dbo.Markets mk on OO.ccode = mk.CountryID And MK.Market ='Germany'
	WHERE		NULLIF(Surname,'') IS NULL

	--V1.68
	UPDATE		OO
	SET			Dealer = Franchises.LocalTradingTitle1
	FROM		SelectionOutput.OnlineOutput	OO
	INNER JOIN
	(
		SELECT	DISTINCT ET.EventTypeID, FR.*	
		FROM		dbo.Franchises		FR
		INNER JOIN	Event.EventTypes	ET ON FR.OutletFunctionID = ET.RelatedOutletFunctionID
	)	Franchises ON	OO.etype			= Franchises.EventTypeID AND 
						OO.OutletPartyID	= Franchises.OutletPartyID AND
						OO.manuf			= Franchises.ManufacturerPartyID

	INNER JOIN		dbo.Markets MK ON	OO.ccode	= MK.CountryID
	WHERE			MK.DealerTableEquivMarket	= 'Taiwan'


	--V1.70
	--Update Market to alternative Market output name
	UPDATE OO
	SET OO.CTRY = M.MarketOutputTxt
	FROM SelectionOutput.OnlineOutput OO
	INNER JOIN dbo.Markets M ON OO.CTRY = M.Market
	WHERE M.MarketOutputTxt IS NOT NULL

END TRY

BEGIN CATCH

	EXEC dbo.usp_RethrowError
		
END CATCH

