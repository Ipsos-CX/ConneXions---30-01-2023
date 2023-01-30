CREATE VIEW [dbo].[vwBrandMarketQuestionnaireSampleMetadata]
WITH SCHEMABINDING
AS


	SELECT DISTINCT
	 BMQ.BMQID
	,B.ManufacturerPartyID
	,B.Brand
	,M.Market
	,R.Region
	,C.ISOAlpha3
	,M.CountryID
	,Q.Questionnaire
	,BMQS.QuestionnaireRequirementID
	,BMQS.DealerCodeOriginatorPartyID
	,BMQ.SampleLoadActive
	,BMQ.PersonRequired
	,BMQ.OrganisationRequired
	,BMQ.StreetRequired
    ,BMQ.PostcodeRequired
    ,BMQ.EmailRequired
    ,BMQ.TelephoneRequired
    ,BMQ.StreetOrEmailRequired
    ,BMQ.TelephoneOrEmailRequired
    ,BMQ.MobilePhoneRequired
    ,BMQ.MobilePhoneOrEmailRequired
    ,BMQ.LanguageRequired
    ,BMQ.SelectSales
    ,BMQ.SelectPreOwned
    ,BMQ.SelectService
    ,BMQ.SelectWarranty
    ,BMQ.SelectRoadside
	,BMQ.SelectCRC
	,BMQ.SelectLostLeads
	,BMQ.SelectBodyshop
	,BMQ.SelectIAssistance
	,BMQ.SelectPreOwnedLostLeads
	,BMQ.SelectCQI1MIS		-- TASK 917
	,BMQ.SelectCQI3MIS
	,BMQ.SelectCQI24MIS
	,BMQ.SelectMCQI1MIS
	,BMQ.SelectGeneralEnquiry
	,BMQ.SelectLandRoverExperience
	,BMQ.SelectionOutputActive
	,BMQ.IncludeEmailOutputInAllFile
	,BMQ.IncludePostalOutputInAllFile
	,BMQ.IncludeCATIOutputInAllFile
	,BMQ.IncludeSMSOutputInAllFile
	,BMQS.SetNameCapitalisation
	,S.SampleFileID
	,S.SampleFileSource
	,S.SampleFileDestination
	,S.SampleFileNamePrefix
	,S.SampleFileExtension
	,BMQ.OverrideSample_Salutation --task 538
	,BMQS.CreateSelection
	,BMQS.SampleTriggeredSelection
	,BMQS.UpdateSelectionLogging
	,BMQS.SelectionName
	,BMQ.ContactMethodologyTypeID
	,BMQ.ContactMethodologyFromDate
	,M.SMSOutputByLanguage
	,BMQ.NumDaysToExpireOnlineQuestionnaire
	,BMQ.CATIMerged
	,BMQ.CATIMergedType
	,BMQ.PostalMerged
	,BMQ.PostalMergedType
FROM dbo.BrandMarketQuestionnaireMetadata BMQ
INNER JOIN dbo.Brands B ON B.BrandID= BMQ.BrandID
INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
INNER JOIN dbo.Regions R ON R.RegionID = M.RegionID
INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
INNER JOIN dbo.BrandMarketQuestionnaireSampleMetadata BMQS ON BMQS.BMQID = BMQ.BMQID
INNER JOIN dbo.SampleFileMetadata S ON S.SampleFileID = BMQS.SampleFileID
INNER JOIN ContactMechanism.Countries C ON C.CountryID = M.CountryID
WHERE BMQS.Enabled = 1;




