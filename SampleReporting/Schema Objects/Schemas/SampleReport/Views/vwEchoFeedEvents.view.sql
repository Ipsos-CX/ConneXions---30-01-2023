CREATE VIEW [SampleReport].[vwEchoFeedEvents]
AS


/*
	Purpose:	Return data to be fed into the Echo system
	
	Version		Date		Deveoloper				Comment
	?			?			?						- Unsure of previous versions as no in-line comments before v1.1
	1.1			26/04/2017	Chris Ross				BUG 13364 - Add in Customer Preference columns
	1.2		    17/05/2017	Ben King				BUG 13933 & 13884 - Add fields SVCRMSalesType, SVCRMInvalidSalesType, DealNumber, RepairOrderNumber, VistaCommonOrderNumber	
	1.3			24/05/2017	Ben King			    BUG 13950 - Echo reporting change - employee reporting for generic roles
	1.4		    31/05/2017	Ben King			    BUG 13985 - Echo Report Changes: Add AuditItemId and correct Sales codes & Names variables.
	1.5		    20/06/2017  Ben King				BUG 14033 - Add Field RecordChanged to Echo output			
	1.6			07/09/2017	Chris Ross				BUG 14122 - Add in PDIFlagSet column
	1.7			08/09/2017	Eddie Thomas			BUG 14141 - New Bodyshop questionnaire
	1.8		    14/11/20107 Ben King				BUG 14379 - 14379 - New Suppression Logic_for Sample Reporting Purposes
	1.9		    21/12/2017	Ben King			    BUG 14455 - Anonymity on Sample reporting website
	1.10		19/01/2018	Ben King				BUG 14493 - Add anonymous flags to echo output	
	1.11		19/01/2018	Ben King				BUG 14487 - OtherExclusion field
	1.12		14/03/2018	Ben King			    BUG 14486 - Customer Preference Override Flag	
	1.13		01/05/2018	Ben King			    BUG 14669 - GDPR New Flag_ Sample Reporting	
	1.14		03/01/2020	Ben King			    BUG 16864 - Add exclusion category flags
	1.15		02/02/2021	Ben King				BUG 18093 - add 10digit code (plus other fields)
	1.16		25/02/2021	Ben King				BUG 18126 - ADD EventID to Website sample reporting.
	1.17		10/03/2021	Ben King				BUG 18128 - Sample Reporting: Filter on "Core" markets when base table builds
	1.18		23/03/2021  Ben King                BUG 18153 - Sample Reporting - Report & remove selected without 10 Dig Dealer code
	1.19		26/03/2021	Ben King			    BUG 18158 - Add the crc agent cdsid field to sample reports feed
	1.20        23/04/2021  Ben King                BUG 18188 - Medallia Sample reporting files - update needed to PII (N/A) fields to not be blanked out
	1.21		10/06/2021	Ben King			    TASK 474 - Japan Purchase - Mismatch between Dealer and VIN
	1.22		17/06/2021	Ben King				TASK 495 - Sample reporting for General Enquiries
	1.23        02/11/2021  Ben King                TASK 646 - Lost Leads Sample reporting feed for Medallia
	1.24		30/09/2022	Eddie Thomas			TASK 1017 - Adding SubBrand
	1.25		05/10/2022	Eddie Thomas			TASK 926 - Adding ModelCode & ModelDescription
	1.26		13/10/2022	Eddie Thomas			TASK 1064 - Adding LeadVehSaleType & ModelVariant

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
			WHEN 'Roadside' THEN 13 --V1.19
			WHEN 'PreOwned' THEN 15	--V1.19			
			WHEN 'CRC' THEN 14 -- V1.17
			WHEN 'Bodyshop' THEN 17			--V1.7, V1.19					
			WHEN 'CRC General Enquiry' THEN 23	--V1.22
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
		--,CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1 --V1.13
		,CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 --V1.20 removed anonymity flags
		THEN '88'
		ELSE V.ModelID
		END AS ModelID
		, dbo.udfCleanText(IR.SampleEmailAddress,'|') AS EmailInFile
		, dbo.udfCleanText(IR.CaseEmailAddress,'|') AS EmailPreviouslySupplied
		--, IR.RegistrationDate
		--, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1
		, CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 -- V1.20 removed anonymity flags
		  THEN '19700101'
		  ELSE ISNULL(CONVERT(VARCHAR(8), IR.RegistrationDate, 112), '') 
		  END AS RegistrationDate_ECHO -- V1.9, V1.13
		--, DATEDIFF(s, '19700101', IR.RegistrationDate) AS RegistrationDate_DP
		--, IR.EventDate
		--, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1
		, CASE WHEN ISNULL(IR.GDPRflag, 0) = 1 -- V1.20 removed anonymity flags
		  THEN '19700101'
		  ELSE ISNULL(CONVERT(VARCHAR(8), IR.EventDate, 112), '')
		  END AS EventDate_ECHO -- V1.9, V1.13
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
		
		, IR.PreviousEventBounceBack													
		, IR.EventDateTooYoung																
		, CAST(~CAST(IR.SuppliedName AS BIT) AS INT) SMP_NoSuppliedName					
		, CAST(~CAST(IR.SuppliedAddress AS BIT) AS INT) SMP_NoSuppliedAddress			
		, CAST(~CAST(IR.SuppliedPhoneNumber AS BIT) AS INT) SMP_NoSuppliedPhoneNumber	
		, CAST(~CAST(IR.SuppliedMobilePhone AS BIT) AS INT) SMP_NoSuppliedMobilePhone	
		, CAST(~CAST(IR.SuppliedEmail AS BIT) AS INT) SMP_NoSuppliedEmail				
		, IR.PhoneSuppression AS SMP_PhoneSuppression									
		, IR.AFRLCode AS SMP_AFRLCode													
		, IR.InvalidAFRLCode AS SMP_InvalidAFRLCode										
		, IR.DealerExclusionListMatch AS SEL_DealerExclusionListMatch					
		, IR.SalesType AS SMP_SalesType													
		, IR.InvalidSalesType AS SEL_InvalidSalesType									
		, IR.DataSource
		, IR.AgentCodeFlag
		, IR.HardBounce
		, IR.SoftBounce
		, IR.Unsubscribes
		, IR.PrevHardBounce	
		, IR.PrevSoftBounce
		, IR.[ServiceTechnicianID]				
	    , IR.[ServiceTechnicianName]				
	    , IR.[ServiceAdvisorName]
	    , IR.[ServiceAdvisorID]				 
	    , IR.[CRMSalesmanName]		
	    , IR.[CRMSalesmanCode]
	    , IR.[FOBCode]				-- V1.5												
		, IR.ContactPreferencesSuppression		-- v1.1
		, IR.ContactPreferencesPartySuppress		-- v1.1
		, IR.ContactPreferencesEmailSuppress		-- v1.1
		, IR.ContactPreferencesPhoneSuppress		-- v1.1
		, IR.ContactPreferencesPostalSuppress		-- v1.1
		, IR.SVCRMSalesType																-- v1.2
		, IR.SVCRMInvalidSalesType														-- v1.2
		, IR.DealNumber																	-- v1.3
		, IR.RepairOrderNumber															-- v1.3
		, IR.VistaCommonOrderNumber														-- v1.3
		, IR.SalesEmployeeCode															-- v1.3
		, IR.SalesEmployeeName															-- v1.3
		, IR.ServiceEmployeeCode														-- v1.3
		, IR.ServiceEmployeeName														-- v1.3
		, IR.[AuditItemID]																-- V1.4
		, IR.RecordChanged																-- V1.5
		, IR.PDIFlagSet																	-- V1.6
		, IR.OriginalPartySuppression													-- V1.8
		, IR.OriginalPostalSuppression													-- V1.8
		, IR.OriginalEmailSuppression													-- V1.8
		, IR.OriginalPhoneSuppression													-- V1.8
		, IR.AnonymityDealer															-- V1.10
		, IR.AnonymityManufacturer														-- V1.10
		, IR.OtherExclusion																-- V1.11
		, IR.OverrideFlag																-- V1.12
		, IR.GDPRflag																	-- V1.13
		, IR.EmailExcludeBarred															-- V1.14
	    , IR.EmailExcludeGeneric														-- V1.14
	    , IR.EmailExcludeInvalid														-- V1.14
	    , IR.CompanyExcludeBodyShop														-- V1.14
	    , IR.CompanyExcludeLeasing														-- V1.14
	    , IR.CompanyExcludeFleet														-- V1.14
	    , IR.CompanyExcludeBarredCo														-- V1.14
		, IR.OutletPartyID AS OrignalDealerCode						                    -- V1.15
		, IR.Dealer10DigitCode					                                        -- V1.15
        , IR.OutletFunction AS DealerOutletFunction 						            -- V1.15
	    , IR.RoadsideAssistanceProvider 			                                    -- V1.15
	    , IR.CRC_Owner AS CDSID							                                -- V1.15  (updated name BUG 18158)       
	    , IR.DealerMarket																-- V1.15
		, IR.CountryIsoAlpha2															-- V1.15
		, IR.CRCMarketCode																-- V1.15
		, IR.MatchedODSEventID AS 'EventID'												-- V1.16
		, IR.InvalidDealerBrand															-- V1.21
		, IR.SubBrand																	-- V1.24
		, IR.ModelCode																	-- V1.25
		, IR.OutputFileModelDescription AS ModelDescription								-- V1.25
		, IR.LeadVehSaleType															-- V1.26
		, IR.ModelVariant																-- v1.26
	FROM SampleReport.IndividualRowsEvents IR
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
	WHERE IR.Questionnaire IN ('CRC', 'CRC General Enquiry', 'Roadside')   -- V1.18
	OR   (IR.Questionnaire NOT IN ('CRC', 'CRC General Enquiry', 'Roadside') AND IR.UncodedDealer = 1) -- V1.18
	OR   (IR.Questionnaire NOT IN ('CRC', 'CRC General Enquiry', 'Roadside') AND IR.UncodedDealer = 0 AND LEN(ISNULL(IR.Dealer10DigitCode,'')) > 1) -- V1.18


