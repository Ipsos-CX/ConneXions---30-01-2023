CREATE PROCEDURE [dbo].[uspInMomentLIVEStatus]
    @AuditItemID BIGINT = NULL ,
	@CaseID INT = NULL ,
    @FileName VARCHAR(100) = NULL ,
    @VIN nvarchar(50) = NULL
AS

/*
	Purpose:	Retrieve live website data
		
	Version			Date			Developer			Comment
	1.0				18-10-2019		Ben King			BUG 16662
	1.1				15-01-2020		Chris Ledger 		BUG 15372 - Correct incorrect cases	
	1.2				01-04-2020		Chris Ledger		BUG 15372 - Fix hard coded database references and cases
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	    SELECT
	   IR.ReportDate AS 'IM_Export_Date',
	   IR.FileName,	
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
			WHEN 'Roadside' THEN 3
			WHEN 'PreOwned' THEN 4			--V1.5	
			WHEN 'CRC' THEN 5				--V1.7
			WHEN 'Bodyshop' THEN 6			--V1.17	
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
		,CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1 -- V1.23
		THEN '88'
		ELSE V.ModelID
		END AS ModelID
		, dbo.udfCleanText(IR.SampleEmailAddress,'|') AS EmailInFile
		, dbo.udfCleanText(IR.CaseEmailAddress,'|') AS EmailPreviouslySupplied
		--, IR.RegistrationDate
		, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1 OR ISNULL(IR.GDPRflag, 0) = 1
		  THEN '19700101'
		  ELSE ISNULL(CONVERT(VARCHAR(8), IR.RegistrationDate, 112), '') 
		  END AS RegistrationDate_ECHO -- V1.19, V1.23
		--, DATEDIFF(s, '19700101', IR.RegistrationDate) AS RegistrationDate_DP
		--, IR.EventDate
		, CASE WHEN ISNULL(IR.AnonymityDealer, 0) = 1 OR ISNULL(IR.AnonymityManufacturer, 0) = 1  OR ISNULL(IR.GDPRflag, 0) = 1
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
		, IR.DedupeEqualToEvents														
		, IR.HardBounce																	
		, IR.[SoftBounce]																	
		, IR.Unsubscribes																
		, IR.PrevHardBounce																
		, IR.PrevSoftBounce															
		, IR.[ServiceTechnicianID]																
	    , IR.[ServiceTechnicianName]                                                    			
	    , IR.[ServiceAdvisorName]                                                       
	    , IR.[ServiceAdvisorID]		                                                    	 
	    , IR.[CRMSalesmanName]		                                                    
	    , IR.[CRMSalesmanCode]                                                          
	    , IR.[FOBCode]																	
		, IR.ContactPreferencesSuppression												
		, IR.ContactPreferencesPartySuppress											
		, IR.ContactPreferencesEmailSuppress											
		, IR.ContactPreferencesPhoneSuppress											
		, IR.ContactPreferencesPostalSuppress											
		, IR.SVCRMSalesType																
		, IR.SVCRMInvalidSalesType														
		, IR.DealNumber																	
		, IR.RepairOrderNumber															
		, IR.VistaCommonOrderNumber														
		, IR.SalesEmployeeCode															
		, IR.SalesEmployeeName															
		, IR.ServiceEmployeeCode														
		, IR.ServiceEmployeeName														
		, IR.[AuditItemID]														        
		, IR.RecordChanged																
		, IR.PDIFlagSet																	
		, IR.OriginalPartySuppression													
		, IR.OriginalPostalSuppression													
		, IR.OriginalEmailSuppression													
		, IR.OriginalPhoneSuppression													
		, IR.AnonymityDealer															
		, IR.AnonymityManufacturer														
		, IR.OtherExclusion																
		, IR.OverrideFlag																
		, IR.GDPRflag	
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
		
		
	FROM SampleReport.YearlyEchoHistory IR
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
	 WHERE   ( IR.AuditItemID = @AuditItemID
              OR @AuditItemID IS NULL
            )
            AND ( IR.FileName = @FileName
                  OR @FileName IS NULL
                )
            AND ( IR.CaseID = @CaseID
                  OR @CaseID IS NULL
                )
            AND ( IR.VIN = @VIN
                  OR @VIN IS NULL
                )

	 ORDER BY IR.ReportDate DESC
            
   OPTION  ( RECOMPILE );