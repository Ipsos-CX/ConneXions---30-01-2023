CREATE VIEW [SampleReport].[vwEchoFeedCombined]
AS 

/*
	Purpose:	Return data to be fed into the Medallia
	
	Release		Version		Date		Deveoloper				Comment
	LIVE		1.0			20140609	Martin Riverol			Created
	LIVE		1.1			20140729	Eddie Thomas			Added additional fields
	LIVE		1.2			20150202	Eddie Thomas			Added additional fields
	LIVE		1.3			20151603	Eddie Thomas			Datediff function was generating an overflow error with sample date stamped as 1900-01-01
	LIVE		1.4			2016-03-30  Chris Ledger			R
	LIVE		1.5			20160621	Eddie Thomas			PreOwned surveytype was being output as 0
	LIVE		1.6			29092016	Ben King				BUG 13089 - add AgentCodeFlag
	LIVE		1.7			01112016	Ben King				BUG 13267 - add SurveyTypeId in for Roadside & CRC
	LIVE		1.8			30112016	Ben King				BUG 13358 - add new fields
	LIVE		1.8			30112016	Ben King				BUG 13358 - add new fields
	LIVE		1.9			01022017	Ben King				BUG 13546 - Echo sample reports NA changes - add employee reporting fields
	LIVE		1.10		23032017	Ben King			    BUG 13465 - Add FOBCode to Echo & SampleReports (individual Sheet) 
	LIVE		1.11		26/04/2017	Chris Ross				BUG 13364 - Add in Customer Preference columns
	LIVE		1.12		17/05/2017	Ben King				BUG 13933 & 13884 - Add fields SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber	
	LIVE		1.13		24/05/2017	Ben King			    BUG 13950 - Echo reporting change - employee reporting for generic roles
	LIVE		1.14		31/05/2017	Ben King			    BUG 13985 - Echo Report Changes: Add AuditItemId and correct Sales codes & Names variables.
	LIVE		1.15		20/06/2017  Ben King				BUG 14033 - Add Field RecordChanged to Echo output
	LIVE		1.16		07/09/2017	Chris Ross				BUG 14122 - Add in PDIFlagSet column
	LIVE		1.17		08/09/2017	Eddie Thomas			BUG 14141 - New Bodyshop questionnaire
	LIVE		1.18		14/11/2017  Ben King				BUG 14379 - 14379 - New Suppression Logic_for Sample Reporting Purposes
	LIVE		1.19		21/12/2017	Ben King			    BUG 14455 - Anonymity on Sample reporting website
	LIVE		1.20		19/01/2018	Ben King				BUG 14493 - Add anonymous flags to echo output
	LIVE		1.21		19/01/2018	Ben King				BUG 14487 - OtherExclusion field
	LIVE		1.22		14/03/2018	Ben King			    BUG 14486 - Customer Preference Override Flag		
	LIVE		1.23		01/05/2018	Ben King			    BUG 14669 - GDPR New Flag_ Sample Reporting
	LIVE		1.24		03/01/2020	Ben King			    BUG 16864 - Add exclusion category flags
	LIVE		1.25		02/02/2021	Ben King				BUG 18093 - add 10digit code (plus other fields)
	LIVE		1.26		25/02/2021	Ben King				BUG 18126 - ADD EventID to Website sample reporting.
	LIVE		1.27		10/03/2021	Ben King				BUG 18128 - Sample Reporting: Filter on "Core" markets when base table builds
	LIVE		1.28		23/03/2021  Ben King                BUG 18153 - Sample Reporting - Report & remove selected without 10 Dig Dealer code
	LIVE		1.29		26/03/2021	Ben King			    BUG 18158 - Add the crc agent cdsid field to sample reports feed
	LIVE		1.30        23/04/2021  Ben King                BUG 18188 - Medallia Sample reporting files - update needed to PII (N/A) fields to not be blanked out
	LIVE		1.31		10/06/2021	Ben King				TASK 474 - Japan Purchase - Mismatch between Dealer and VIN
	LIVE		1.32		17/06/2021	Ben King				TASK 495 - Sample reporting for General Enquiries
	LIVE		1.33        02/11/2021  Ben King                TASK 646 - Lost Leads Sample reporting feed for Medallia
	LIVE		1.34		30/09/2022	Eddie Thomas			TASK 1017 - Add SubBrand
	LIVE		1.35		05/10/2022	Eddie Thomas			TASK 926 - Adding ModelCode & ModelDescription 
	LIVE		1.36		13/10/2022	Eddie Thomas			TASK 1064 - Adding LeadVehSaleType & ModelVariant
	LIVE		1.37		31/10/2022  Ben King                TASK 1053 - 19616 - Sample Health - clear out reasons for non selections for duplicates
*/

	SELECT 
		-- IR.LoadedDate AS [Date]
		Case	 
				When IR.LoadedDate < '19700101' Then null
				ELSE CONVERT(CHAR(8), IR.LoadedDate, 112)
		End  AS [Date_ECHO]
		,Case	 
				When IR.LoadedDate < '19700101' Then null
				Else	DATEDIFF(s, '19700101', IR.LoadedDate)
		End  AS [Date_DP]
		--, IR.DealerMarket
		--, IR.Questionnaire
		--, IR.Questionnaire AS SurveyType
		, CASE IR.Questionnaire
			WHEN 'Sales' THEN 1
			WHEN 'Service' THEN 2
			WHEN 'Roadside' THEN 13			--V1.29
			WHEN 'PreOwned' THEN 15			--V1.5, V1.29	
			WHEN 'CRC' THEN 14				--V1.7, V1.27
			WHEN 'Bodyshop' THEN 17			--V1.17, V1.29	
			WHEN 'CRC General Enquiry' THEN 23 --V1.32
			WHEN 'LostLeads' THEN 16
			ELSE 0
		END AS SurveyTypeID
		, SL.ManufacturerID
		, dbo.udfCleanText(IR.DealerCode,'|')  AS DealerCode
		, IR.DealerCodeGDD
		, COALESCE(NULLIF(SL.SalesDealerID, 0), NULLIF(SL.ServiceDealerID, 0), NULLIF(SL.BodyshopDealerID,0)) AS DealerPartyID
		, IR.CountryID
		--, IR.DealerName
		, dbo.udfCleanText(IR.FullName,'|') AS FullName
		, dbo.udfCleanText(IR.OrganisationName,'|') AS OrganisationName 
		, dbo.udfCleanText(IR.RegistrationNumber,'|') AS RegistrationNumber 
		, dbo.udfCleanText(IR.VIN,'|') AS VIN
		--, IR.OutputFileModelDescription AS Model
		--,CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1 -- V1.23
		,CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 -- V1.23, V1.30 Remove Anonymity flags
		THEN '88'
		ELSE V.ModelID
		END AS ModelID
		, dbo.udfCleanText(IR.SampleEmailAddress,'|') AS EmailInFile
		, dbo.udfCleanText(IR.CaseEmailAddress,'|') AS EmailPreviouslySupplied
		--, IR.RegistrationDate
		--, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1
		, CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 -- V1.30 Remove Anonymity flags
		  THEN '19700101'
		  ELSE ISNULL(CONVERT(VARCHAR(8), IR.RegistrationDate, 112), '') 
		  END AS RegistrationDate_ECHO -- V1.19, V1.23
		--, DATEDIFF(s, '19700101', IR.RegistrationDate) AS RegistrationDate_DP
		--, IR.EventDate
		--, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1  OR ISNULL(IR.GDPRflag, 0) = 1
		, CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 -- V1.30 Remove Anonymity flags
		  THEN '19700101'
		  ELSE ISNULL(CONVERT(VARCHAR(8), IR.EventDate, 112), '')
		  END AS EventDate_ECHO -- V1.19, V1.23
		--, DATEDIFF(s, '19700101', IR.RegistrationDate) AS EventDate_DP
		--, CASE WHEN IR.UsableFlag = 1 THEN 'Yes' ELSE 'No' END AS Usable
		, ISNULL(IR.UsableFlag, 0) AS UsableFlag
		--, CASE WHEN IR.SentFlag = 1 THEN 'Yes' ELSE 'No' END AS [Sent]
		, ISNULL(IR.SentFlag, 0) AS SentFlag
		--, IR.SentDate AS DateSent
		, ISNULL(CONVERT(VARCHAR(8), IR.SentDate, 112), '') AS DateSent_ECHO
		--, DATEDIFF(s, '19700101', IR.SentDate) AS SentDate_DP
		--, IR.CaseOutputType AS ContactMethodEmailPostalSMS
		, COT.CaseOutputTypeID AS ContactMethodID
		--, IR.SuppliedName AS SMP_SuppliedName
		--, IR.SuppliedAddress AS SMP_SuppliedAddress
		--, IR.SuppliedPhoneNumber AS SMP_SuppliedPhoneNumber
		--, IR.SuppliedMobilePhone AS SMP_SuppliedMobilePhone
		--, IR.SuppliedEmail AS SMP_SuppliedEmail
		, IR.SuppliedVehicle AS SMP_SuppliedVehicle
		, IR.SuppliedRegistration AS SMP_SuppliedRegistration
		--, IR.SuppliedEventDate AS SMP_SuppliedEventDate
		, CAST(~CAST(IR.SuppliedEventDate AS BIT) AS INT) AS SMP_SuppliedEventDate
		, IR.EventNonSolicitation AS SMP_EventNonSolicitation
		, IR.PartySuppression AS SMP_PartySuppression
		, IR.EmailSuppression AS SMP_EmailSuppression
		, IR.PostalSuppression AS SMP_PostalSuppression
		, IR.PartyNonSolicitation AS SMP_PartyNonSolicitation
		, IR.EventDateOutOfDate AS SMP_EventOutOfDate
		, IR.UncodedDealer AS SMP_UncodedDealer
		, IR.InternalDealer AS SMP_NDVODealer
		, IR.InvalidManufacturer AS SMP_InvalidManufacturer 
		, ISNULL(IR.DuplicateRowFlag, 0) AS SMP_DuplicateRowFlag
		, IR.NonLatestEvent AS SEL_NonLatestEvent
		, IR.RecontactPeriod AS SEL_WithinRecontactPeriod
		, IR.RelativeRecontactPeriod AS SEL_RelativeRecontactPeriod
		, IR.ExclusionListMatch AS SEL_OnExclusionList
		, IR.BarredEmailAddress AS SEL_BarredEmail
		, IR.BarredDomain AS SEL_BarredDomain
		, IR.InvalidEmailAddress AS SEL_InvalidEmailAddress
		, ISNULL(IR.BouncebackFlag,0)	AS SMP_BouncebackFlag
		, IR.MissingLanguage AS SMP_MissingLanguageCode   
		, IR.MissingMobilePhone AS SEL_MissingMobilePhone
		, IR.MissingMobilePhoneAndEmail AS SEL_MissingMobilePhoneAndEmail
		, IR.EventAlreadySelected AS SEL_EventAlreadySelected
		, IR.InvalidOwnershipCycle AS SEL_InvalidOwnershipCycle
		, IR.InvalidVehicleRole AS SEL_InvalidVehicleRole
		, IR.CrossBorderAddress AS SEL_CrossBorderAddress
		, IR.CrossBorderDealer AS SEL_CrossBorderDealer
		, IR.WrongEventType AS SEL_WrongEventType
		, IR.MissingStreet AS SEL_MissingStreet
		, IR.MissingPostcode AS SEL_MissingPostCode
		, IR.MissingEmail AS SEL_MissingEmail
		, IR.MissingTelephone AS SEL_MissingTelephone
		, IR.MissingStreetAndEmail AS SEL_MissingStreetAndEmail
		, IR.MissingTelephoneAndEmail AS SEL_MissingTelephoneAndEmail
		, IR.InvalidModel AS SEL_InvalidModel
		, IR.MissingPartyName AS SEL_MissingPartyName
		, ISNULL(IR.ManualRejectionFlag, 0) AS SEL_ManualRejection
		, ISNULL(REPLICATE('0', 8 - LEN(IR.CaseID)) + CAST(IR.CaseID AS VARCHAR(8)), '') AS CaseID
		, ISNULL(IR.RespondedFlag, 0) AS RespondedFlag 
		--, IR.ClosureDate AS RespondedDate
		, ISNULL(CONVERT(VARCHAR(8), IR.ClosureDate, 112), '') AS RespondedDate_ECHO
		--, DATEDIFF(s, '19700101', IR.ClosureDate) AS RespondedDate_DP
		--, 'X' AS EventType
		, SL.ODSEventTypeID AS EventTypeID
		, IR.UnmatchedModel AS SMP_UnmatchedModel
		
		, IR.PreviousEventBounceBack													--V1.2
		, IR.EventDateTooYoung															--V1.2			
		, CAST(~CAST(IR.SuppliedName AS BIT) AS INT) SMP_NoSuppliedName					--V1.2	
		, CAST(~CAST(IR.SuppliedAddress AS BIT) AS INT) SMP_NoSuppliedAddress			--V1.2
		, CAST(~CAST(IR.SuppliedPhoneNumber AS BIT) AS INT) SMP_NoSuppliedPhoneNumber	--V1.2
		, CAST(~CAST(IR.SuppliedMobilePhone AS BIT) AS INT) SMP_NoSuppliedMobilePhone	--V1.2	
		, CAST(~CAST(IR.SuppliedEmail AS BIT) AS INT) SMP_NoSuppliedEmail				--V1.2
		, IR.PhoneSuppression AS SMP_PhoneSuppression									-- V1.4
		, IR.AFRLCode AS SMP_AFRLCode													-- V1.4
		, IR.InvalidAFRLCode AS SMP_InvalidAFRLCode										-- V1.4
		, IR.DealerExclusionListMatch AS SEL_DealerExclusionListMatch					-- V1.4
		, IR.SalesType AS SMP_SalesType													-- V1.4
		, IR.InvalidSalesType AS SEL_InvalidSalesType									-- V1.4	
		, IR.DataSource
		, IR.AgentCodeFlag
		, IR.DedupeEqualToEvents														-- V1.8
		, IR.HardBounce																	-- V1.8
		, IR.SoftBounce																	-- V1.8
		, IR.Unsubscribes																-- V1.8
		, IR.PrevHardBounce																-- V1.8
		, IR.PrevSoftBounce																-- V1.8
		, IR.[ServiceTechnicianID]														-- V1.9			
	    , IR.[ServiceTechnicianName]                                                    -- V1.9				
	    , IR.[ServiceAdvisorName]                                                       -- V1.9
	    , IR.[ServiceAdvisorID]		                                                    -- V1.9		 
	    , IR.[CRMSalesmanName]		                                                    -- V1.9
	    , IR.[CRMSalesmanCode]                                                          -- V1.9
	    , IR.[FOBCode]																	-- V1.10
		, IR.ContactPreferencesSuppression												-- v1.11
		, IR.ContactPreferencesPartySuppress											-- v1.11
		, IR.ContactPreferencesEmailSuppress											-- v1.11
		, IR.ContactPreferencesPhoneSuppress											-- v1.11
		, IR.ContactPreferencesPostalSuppress											-- v1.11
		, IR.SVCRMSalesType																-- v1.12
		, IR.SVCRMInvalidSalesType														-- v1.12
		, IR.DealNumber																	-- v1.12
		, IR.RepairOrderNumber															-- v1.12
		, IR.VistaCommonOrderNumber														-- v1.12
		, IR.SalesEmployeeCode															-- v1.13
		, IR.SalesEmployeeName															-- v1.13
		, IR.ServiceEmployeeCode														-- v1.13
		, IR.ServiceEmployeeName														-- v1.13
		, IR.[AuditItemID]														        -- v1.14
		, IR.RecordChanged																-- V1.15
		, IR.PDIFlagSet																	-- V1.16
		, IR.OriginalPartySuppression													-- V1.17
		, IR.OriginalPostalSuppression													-- V1.17
		, IR.OriginalEmailSuppression													-- V1.17
		, IR.OriginalPhoneSuppression													-- V1.17
		, IR.AnonymityDealer															-- V1.20
		, IR.AnonymityManufacturer														-- V1.20
		, IR.OtherExclusion																-- V1.21
		, IR.OverrideFlag																-- V1.22
		, IR.GDPRflag																	-- V1.23
		, IR.EmailExcludeBarred															-- V1.24
	    , IR.EmailExcludeGeneric														-- V1.24
	    , IR.EmailExcludeInvalid														-- V1.24
	    , IR.CompanyExcludeBodyShop														-- V1.24
	    , IR.CompanyExcludeLeasing														-- V1.24
	    , IR.CompanyExcludeFleet														-- V1.24
	    , IR.CompanyExcludeBarredCo														-- V1.24
		, IR.OutletPartyID AS OrignalDealerCode						                    -- V1.25
		, IR.Dealer10DigitCode					                                        -- V1.25
        , IR.OutletFunction AS DealerOutletFunction 						            -- V1.25
	    , IR.RoadsideAssistanceProvider 			                                    -- V1.25
	    , IR.CRC_Owner AS CDSID							                                -- V1.25    (updated name BUG 18158)     
	    , IR.DealerMarket																-- V1.25
		, IR.CountryIsoAlpha2															-- V1.25
		, IR.CRCMarketCode																-- V1.25
		, IR.MatchedODSEventID AS 'EventID'												-- V1.26
		, IR.InvalidDealerBrand															-- V1.31
		, IR.SubBrand																	-- V1.34
		, IR.ModelCode																	-- V1.35
		, IR.OutputFileModelDescription AS ModelDescription								-- V1.35
		, IR.LeadVehSaleType															-- V1.36
		, IR.ModelVariant-- V1.36
		, NoMatch_CRCAgent -- V1.37
		, NoMatch_InviteBMQ -- V1.37
		, NoMatch_InviteLanguage -- V1.37

	FROM SampleReport.IndividualRowsCombined IR
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON IR.AuditItemID = SL.AuditItemID
	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON SL.MatchedODSVehicleID = V.VehicleID
	LEFT JOIN 
		(
			SELECT 0 CaseOutputTypeID, '' CaseOutputType
			UNION
			SELECT CaseOutputTypeID, CaseOutputType
			FROM [$(SampleDB)].Event.CaseOutputTypes
		) COT ON
	CASE WHEN IR.CaseOutputType = 'PHONE' THEN 'CATI' ELSE IR.CaseOutputType END = COT.CaseOutputType
	WHERE IR.Questionnaire IN ('CRC', 'CRC General Enquiry', 'Roadside')   -- V1.28
	OR   (IR.Questionnaire NOT IN ('CRC', 'CRC General Enquiry', 'Roadside') AND IR.UncodedDealer = 1) -- V1.28
	OR   (IR.Questionnaire NOT IN ('CRC', 'CRC General Enquiry', 'Roadside') AND IR.UncodedDealer = 0 AND LEN(ISNULL(IR.Dealer10DigitCode,'')) > 1) -- V1.28
GO