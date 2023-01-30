CREATE PROCEDURE [Migration].[uspAddMetadata]
AS


SET IDENTITY_INSERT dbo.Brands ON
INSERT INTO dbo.Brands (BrandID, Brand, ManufacturerPartyID) VALUES
(1, 'Jaguar', 2),
(2, 'Land Rover', 3)
SET IDENTITY_INSERT dbo.Brands OFF

SET IDENTITY_INSERT dbo.Markets ON
INSERT INTO dbo.Markets (MarketID, Market, CountryID)
SELECT 1, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Australia'
UNION
SELECT 2, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Austria'
UNION
SELECT 3, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Belgium'
UNION
SELECT 4, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Brazil'
UNION
SELECT 5, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'China'
UNION
SELECT 6, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'France'
UNION
SELECT 7, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Germany'
UNION
SELECT 8, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Ireland'
UNION
SELECT 9, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Italy'
UNION
SELECT 10, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Japan'
UNION
SELECT 11, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Luxembourg'
UNION
SELECT 12, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Netherlands'
UNION
SELECT 13, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Portugal'
UNION
SELECT 14, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Russian Federation'
UNION
SELECT 15, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Spain'
UNION
SELECT 16, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'Switzerland'
UNION
SELECT 17, Country, CountryID FROM ContactMechanism.Countries WHERE Country = 'United Kingdom'
SET IDENTITY_INSERT dbo.Markets OFF

SET IDENTITY_INSERT dbo.Questionnaires ON
INSERT INTO dbo.Questionnaires (QuestionnaireID, Questionnaire) VALUES
(1, 'Sales'),
(2, 'Service'),
(3, 'Roadside')
SET IDENTITY_INSERT dbo.Questionnaires OFF

INSERT INTO dbo.BrandMarketQuestionnaireMetadata
(
	 BrandID
	,MarketID
	,QuestionnaireID
	,SampleLoadActive
	,StreetRequired
    ,PostcodeRequired
    ,EmailRequired
    ,TelephoneRequired
    ,StreetOrEmailRequired
    ,TelephoneOrEmailRequired
    ,SelectSales
    ,SelectService
    ,SelectWarranty   
	,SelectionOutputActive
	,IncludeEmailOutputInAllFile
	,IncludePostalOutputInAllFile
	,IncludeCATIOutputInAllFile
	,IncludeInOnlineDealerList  
)
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Australia') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Australia') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Austria') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Austria') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Belgium') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Belgium') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'China') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'China') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'France') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'France') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Germany') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Germany') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Ireland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Ireland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Italy') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Italy') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Japan') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Japan') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Luxembourg') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Luxembourg') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Netherlands') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Netherlands') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Portugal') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Portugal') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Russian Federation') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Russian Federation') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Spain') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Spain') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Switzerland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Switzerland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,1 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,1 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Australia') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Australia') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Austria') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Austria') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Belgium') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Belgium') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Brazil') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,0 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Brazil') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,0 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'China') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'China') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'France') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'France') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Germany') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Germany') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Ireland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Ireland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Italy') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Italy') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Japan') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Japan') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Luxembourg') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Luxembourg') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Netherlands') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Netherlands') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Portugal') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Portugal') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Russian Federation') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Russian Federation') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Spain') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Spain') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Switzerland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'Switzerland') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,0 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Sales') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,1 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Service') AS QuestionnaireID
	,1 AS SampleLoadActive
	,1 AS StreetRequired
    ,1 AS PostcodeRequired
    ,0 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,1 AS SelectSales
    ,1 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,1 AS IncludePostalOutputInAllFile
	,1 AS IncludeCATIOutputInAllFile
	,1 AS IncludeInOnlineDealerList
UNION
	SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Land Rover') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Roadside') AS QuestionnaireID
	,1 AS SampleLoadActive
	,0 AS StreetRequired
    ,0 AS PostcodeRequired
    ,1 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,0 AS SelectSales
    ,0 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,0 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,0 AS IncludeInOnlineDealerList
UNION 
	SELECT
	 (SELECT BrandID FROM dbo.Brands WHERE Brand = 'Jaguar') AS BrandID
	,(SELECT MarketID FROM dbo.Markets WHERE Market = 'United Kingdom') AS MarketID
	,(SELECT QuestionnaireID FROM dbo.Questionnaires WHERE Questionnaire = 'Roadside') AS QuestionnaireID
	,1 AS SampleLoadActive
	,0 AS StreetRequired
    ,0 AS PostcodeRequired
    ,1 AS EmailRequired
    ,0 AS TelephoneRequired
    ,0 AS StreetOrEmailRequired
    ,0 AS TelephoneOrEmailRequired
    ,0 AS SelectSales
    ,0 AS SelectService
    ,0 AS SelectWarranty   
	,1 AS SelectionOutputActive
	,1 AS IncludeEmailOutputInAllFile
	,0 AS IncludePostalOutputInAllFile
	,0 AS IncludeCATIOutputInAllFile
	,0 AS IncludeInOnlineDealerList
ORDER BY BrandID, MarketID, QuestionnaireID


--- Set SelectRoadside flag for Roadside BMQ

UPDATE BrandMarketQuestionnaireMetadata
SET SelectRoadside = 1
where BMQID in (
				  SELECT BMQID
				  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
				  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
				  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
				  WHERE M.Market = 'United Kingdom'
				  AND Q.Questionnaire = 'Roadside'
				)



INSERT INTO dbo.SampleFileMetadata (SampleFileSource, SampleFileDestination, SampleFileNamePrefix, SampleFileExtension)
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Combined_DDW_Service' AS SampleFileDestination,
	'Combined_DDW_Service' AS SampleFileNamePrefix,
	'.xls' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Australia_Sales' AS SampleFileDestination,
	'Jaguar_Australia_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Australia_Service' AS SampleFileDestination,
	'Jaguar_Australia_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Austria_Sales' AS SampleFileDestination,
	'Jaguar_Austria_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_China_Sales' AS SampleFileDestination,
	'Jaguar_China_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_China_Service' AS SampleFileDestination,
	'Jaguar_China_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Cupid_Sales' AS SampleFileDestination,
	'Jaguar_Cupid_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_France_Service' AS SampleFileDestination,
	'Jaguar_France_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Germany_Sales' AS SampleFileDestination,
	'Jaguar_Germany_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Germany_Service' AS SampleFileDestination,
	'Jaguar_Germany_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Ireland_Sales' AS SampleFileDestination,
	'Jaguar_Ireland_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Italy_Sales' AS SampleFileDestination,
	'Jaguar_Italy_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Japan_Sales' AS SampleFileDestination,
	'Jaguar_Japan_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Japan_Service' AS SampleFileDestination,
	'Jaguar_Japan_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Netherlands_Sales' AS SampleFileDestination,
	'Jaguar_Netherlands_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Netherlands_Service' AS SampleFileDestination,
	'Jaguar_Netherlands_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Portugal_Service' AS SampleFileDestination,
	'Jaguar_Portugal_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Russia_Sales' AS SampleFileDestination,
	'Jaguar_Russia_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Russia_Service' AS SampleFileDestination,
	'Jaguar_Russia_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Spain_Service' AS SampleFileDestination,
	'Jaguar_Spain_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Switzerland_Sales' AS SampleFileDestination,
	'Jaguar_Switzerland_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_Switzerland_Service' AS SampleFileDestination,
	'Jaguar_Switzerland_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Jaguar_UK_Service' AS SampleFileDestination,
	'Jaguar_UK_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Australia_Sales' AS SampleFileDestination,
	'LandRover_Australia_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Australia_Service' AS SampleFileDestination,
	'LandRover_Australia_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Austria_Sales' AS SampleFileDestination,
	'LandRover_Austria_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Belgium_Sales' AS SampleFileDestination,
	'LandRover_Belgium_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Brazil_Sales' AS SampleFileDestination,
	'LandRover_Brazil_Sales' AS SampleFileNamePrefix,
	'.csv' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Brazil_Service' AS SampleFileDestination,
	'LandRover_Brazil_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_China_Sales' AS SampleFileDestination,
	'LandRover_China_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_China_Service' AS SampleFileDestination,
	'LandRover_China_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_France_Sales' AS SampleFileDestination,
	'LandRover_France_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_France_Service' AS SampleFileDestination,
	'LandRover_France_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Germany_Sales' AS SampleFileDestination,
	'LandRover_Germany_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Germany_Service' AS SampleFileDestination,
	'LandRover_Germany_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Ireland_Sales' AS SampleFileDestination,
	'LandRover_Ireland_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Italy_Sales' AS SampleFileDestination,
	'LandRover_Italy_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Japan_Sales' AS SampleFileDestination,
	'LandRover_Japan_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Japan_Service' AS SampleFileDestination,
	'LandRover_Japan_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Netherlands_Sales' AS SampleFileDestination,
	'LandRover_Netherlands_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Netherlands_Service' AS SampleFileDestination,
	'LandRover_Netherlands_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Portugal_Service' AS SampleFileDestination,
	'LandRover_Portugal_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Russia_Sales' AS SampleFileDestination,
	'LandRover_Russia_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Russia_Service' AS SampleFileDestination,
	'LandRover_Russia_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Spain_Sales' AS SampleFileDestination,
	'LandRover_Spain_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Spain_Service' AS SampleFileDestination,
	'LandRover_Spain_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Switzerland_Sales' AS SampleFileDestination,
	'LandRover_Switzerland_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_Switzerland_Service' AS SampleFileDestination,
	'LandRover_Switzerland_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_UK_Sales' AS SampleFileDestination,
	'LandRover_UK_Sales' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'LandRover_UK_Service' AS SampleFileDestination,
	'LandRover_UK_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension
UNION	
SELECT DISTINCT 
	'$(SampleFileSource)' AS SampleFileSource, 
	'$(SampleFileDestinationPrefix)' + 'Combined_Roadside_Service' AS SampleFileDestination,
	'Combined_Roadside_Service' AS SampleFileNamePrefix,
	'.txt' AS SampleFileExtension





INSERT INTO dbo.BrandMarketQuestionnaireSampleMetadata (BMQID, SampleFileID, SetNameCapitalisation, QuestionnaireRequirementID, DealerCodeOriginatorPartyID, SelectionName, CreateSelection, Enabled)

SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Austria'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,342 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_AUT_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Belgium'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,295 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_BEL_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,344 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_CHE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,271 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_ESP_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,277 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_FRA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,234 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_GBR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Ireland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,338 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_IRE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Italy'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,253 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_ITA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,292 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_JPN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Luxembourg'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,23728 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_LUX_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Austria'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,263 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_AUT_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Belgium'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,224 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_BEL_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,2565 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_CHE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,884 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_ESP_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,5 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_FRA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,31 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_GBR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Ireland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,182 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_IRE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Italy'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,200 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_ITA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,236 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_JPN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Luxembourg'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_DDW_Service'
 )
 ,0 AS SetNameCapitalisation
 ,28618 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_LUX_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Australia'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Australia_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,17606 AS QuestionnaireRequirementID
 ,6 AS DealerCodeOriginatorPartyID
 ,'SAJ_AUS_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Australia'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Australia_Service'
 )
 ,1 AS SetNameCapitalisation
 ,20158 AS QuestionnaireRequirementID
 ,6 AS DealerCodeOriginatorPartyID
 ,'SAJ_AUS_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Austria'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Austria_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,179 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_AUT_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'China'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_China_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,16403 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_CHN_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'China'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_China_Service'
 )
 ,0 AS SetNameCapitalisation
 ,16404 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_CHN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Belgium'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,18 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_BEL_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,35 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_ESP_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,32 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_FRA_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,92 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_GBR_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Luxembourg'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,8280 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_LUX_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Portugal'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,18615 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_POR_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,152 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAL_ESP_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Portugal'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,18658 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAL_POR_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_France_Service'
 )
 ,0 AS SetNameCapitalisation
 ,277 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_FRA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Germany'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Germany_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,6 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_DEU_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Germany'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Germany_Service'
 )
 ,0 AS SetNameCapitalisation
 ,272 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_DEU_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Ireland'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Ireland_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,536 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_IRE_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Italy'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Italy_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,34 AS QuestionnaireRequirementID
 ,20 AS DealerCodeOriginatorPartyID
 ,'SAJ_ITA_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Japan_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,185 AS QuestionnaireRequirementID
 ,33 AS DealerCodeOriginatorPartyID
 ,'SAJ_JPN_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Japan_Service'
 )
 ,0 AS SetNameCapitalisation
 ,292 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_JPN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Netherlands'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Netherlands_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,93 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_NLD_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Netherlands'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Netherlands_Service'
 )
 ,0 AS SetNameCapitalisation
 ,340 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_NLD_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Portugal'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Portugal_Service'
 )
 ,0 AS SetNameCapitalisation
 ,18007 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_POR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Russian Federation'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Russia_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,10288 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_RUS_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Russian Federation'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Russia_Service'
 )
 ,0 AS SetNameCapitalisation
 ,11614 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_RUS_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Spain_Service'
 )
 ,1 AS SetNameCapitalisation
 ,271 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_ESP_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Switzerland_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,346 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_CHE_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_Switzerland_Service'
 )
 ,0 AS SetNameCapitalisation
 ,344 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_CHE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Jaguar_UK_Service'
 )
 ,0 AS SetNameCapitalisation
 ,234 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_GBR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Australia'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Australia_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,17605 AS QuestionnaireRequirementID
 ,35 AS DealerCodeOriginatorPartyID
 ,'SAL_AUS_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Australia'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Australia_Service'
 )
 ,1 AS SetNameCapitalisation
 ,20157 AS QuestionnaireRequirementID
 ,35 AS DealerCodeOriginatorPartyID
 ,'SAL_AUS_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Austria'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Austria_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,154 AS QuestionnaireRequirementID
 ,25 AS DealerCodeOriginatorPartyID
 ,'SAL_AUT_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Belgium'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Belgium_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,223 AS QuestionnaireRequirementID
 ,36 AS DealerCodeOriginatorPartyID
 ,'SAL_BEL_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Luxembourg'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Belgium_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,28617 AS QuestionnaireRequirementID
 ,36 AS DealerCodeOriginatorPartyID
 ,'SAL_LUX_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Brazil'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Brazil_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,30017 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_BRA_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Brazil'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Brazil_Service'
 )
 ,0 AS SetNameCapitalisation
 ,29815 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_BRA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'China'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_China_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,16405 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_CHN_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'China'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_China_Service'
 )
 ,0 AS SetNameCapitalisation
 ,16406 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_CHN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_France_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,707 AS QuestionnaireRequirementID
 ,17 AS DealerCodeOriginatorPartyID
 ,'SAL_FRA_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'France'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_France_Service'
 )
 ,0 AS SetNameCapitalisation
 ,5 AS QuestionnaireRequirementID
 ,17 AS DealerCodeOriginatorPartyID
 ,'SAL_FRA_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Germany'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Germany_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,194 AS QuestionnaireRequirementID
 ,15 AS DealerCodeOriginatorPartyID
 ,'SAL_DEU_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Germany'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Germany_Service'
 )
 ,0 AS SetNameCapitalisation
 ,195 AS QuestionnaireRequirementID
 ,15 AS DealerCodeOriginatorPartyID
 ,'SAL_DEU_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Ireland'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Ireland_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,155 AS QuestionnaireRequirementID
 ,19 AS DealerCodeOriginatorPartyID
 ,'SAL_IRE_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Italy'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Italy_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,335 AS QuestionnaireRequirementID
 ,20 AS DealerCodeOriginatorPartyID
 ,'SAL_ITA_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Japan_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,207 AS QuestionnaireRequirementID
 ,34 AS DealerCodeOriginatorPartyID
 ,'SAL_JPN_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Japan'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Japan_Service'
 )
 ,0 AS SetNameCapitalisation
 ,236 AS QuestionnaireRequirementID
 ,34 AS DealerCodeOriginatorPartyID
 ,'SAL_JPN_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Netherlands'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Netherlands_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,188 AS QuestionnaireRequirementID
 ,22 AS DealerCodeOriginatorPartyID
 ,'SAL_NLD_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Netherlands'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Netherlands_Service'
 )
 ,0 AS SetNameCapitalisation
 ,189 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_NLD_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Portugal'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Portugal_Service'
 )
 ,0 AS SetNameCapitalisation
 ,18008 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_POR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Russian Federation'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Russia_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,10132 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_RUS_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Russian Federation'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Russia_Service'
 )
 ,0 AS SetNameCapitalisation
 ,11613 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_RUS_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Spain_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,152 AS QuestionnaireRequirementID
 ,16 AS DealerCodeOriginatorPartyID
 ,'SAL_ESP_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Spain'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Spain_Service'
 )
 ,1 AS SetNameCapitalisation
 ,884 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_ESP_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Switzerland_Sales'
 )
 ,0 AS SetNameCapitalisation
 ,2564 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_CHE_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'Switzerland'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_Switzerland_Service'
 )
 ,0 AS SetNameCapitalisation
 ,2565 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_CHE_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Sales'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_UK_Sales'
 )
 ,1 AS SetNameCapitalisation
 ,2 AS QuestionnaireRequirementID
 ,24 AS DealerCodeOriginatorPartyID
 ,'SAL_GBR_Sales_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Service'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'LandRover_UK_Service'
 )
 ,0 AS SetNameCapitalisation
 ,31 AS QuestionnaireRequirementID
 ,24 AS DealerCodeOriginatorPartyID
 ,'SAL_GBR_Service_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
 SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Jaguar'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Roadside'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_Roadside_Service'
 )
 ,0 AS SetNameCapitalisation
 ,31822 AS QuestionnaireRequirementID
 ,2 AS DealerCodeOriginatorPartyID
 ,'SAJ_GBR_Roadside_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
UNION
 SELECT
 (
  SELECT BMQID
  FROM dbo.BrandMarketQuestionnaireMetadata BMQ
  INNER JOIN dbo.Brands B ON B.BrandID = BMQ.BrandID
  INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
  INNER JOIN dbo.Questionnaires Q ON Q.QuestionnaireID = BMQ.QuestionnaireID
  WHERE B.Brand = 'Land Rover'
  AND M.Market = 'United Kingdom'
  AND Q.Questionnaire = 'Roadside'
 ) AS BMQID
 ,(
  SELECT SampleFileID
  FROM dbo.SampleFileMetadata
  WHERE SampleFileNamePrefix = 'Combined_Roadside_Service'
 )
 ,0 AS SetNameCapitalisation
 ,31754 AS QuestionnaireRequirementID
 ,3 AS DealerCodeOriginatorPartyID
 ,'SAL_GBR_Roadside_CSP' AS SelectionName
 ,1 AS CreateSelection
 ,1 AS Enabled
  
 
UPDATE Event.EventTypes
SET EventType = 'Sales'
WHERE EventTypeID = 1






/* Models 

Jaguar:		S-TYPE
			XF
			XJ
			XK
			X-TYPE

Land Rover:	Defender
			Discovery
			Discovery 3
			Freelander
			Freelander 2
			Range Rover
			Range Rover Evoque
			Range Rover Sport
*/

INSERT INTO Vehicle.VehicleMatchingStringTypes (VehicleMatchingStringType) VALUES
('VIN Regular Expression'),
('Model Description')

INSERT INTO Vehicle.Models (ManufacturerPartyID, ModelDescription, OutputFileModelDescription) VALUES
(2, 'Unknown Vehicle', 'Unknown Vehicle'),
(2, 'S-TYPE', 'S-TYPE'),
(2, 'XF', 'XF'),
(2, 'XJ', 'XJ'),
(2, 'XK', 'XK'),
(2, 'X-TYPE', 'X-TYPE'),
(3, 'Unknown Vehicle', 'Unknown Vehicle'),
(3, 'Defender', 'Defender'),
(3, 'Discovery', 'Discovery'),
(3, 'Discovery 3', 'Discovery'),
(3, 'Freelander', 'Freelander'),
(3, 'Freelander 2', 'Freelander 2'),
(3, 'Range Rover', 'Range Rover'),
(3, 'Range Rover Evoque', 'Range Rover Evoque'),
(3, 'Range Rover Sport', 'Range Rover Sport')

INSERT INTO Vehicle.VehicleMatchingStrings (VehicleMatchingStringTypeID, VehicleMatchingString) VALUES
(1, 'SAJ__[0O][123]%'),
(1, 'SAJ__0[0-9]____[RST]%'),
(1, 'SAJ__[123789]%'),
(1, 'SAJ__4%'),
(1, 'SAJ__5%'),
(1, 'SALLD%'),
(1, 'SALL[JT]%'),
(1, 'SALLA%'),
(1, 'SALLN%'),
(1, 'SALF[AB]%'),
(1, 'SALL[HMP]%'),
(1, 'SALV%'),
(1, 'SALLS%'),
(2, '%S-TYPE%'),
(2, '%XF%'),
(2, '%XJ%'),
(2, '%XK%'),
(2, '%X-TYPE%'),
(2, '%Defender%'),
(2, '%Discovery%'),
(2, '%Freelander%'),
(2, '%Range%Rover%'),
(2, '%Evoque%')

INSERT INTO Vehicle.ModelMatching (ModelID, VehicleMatchingStringID) VALUES
(2,1),
(3,2),
(4,3),
(5,4),
(6,5),
(8,6),
(9,7),
(10,8),
(11,9),
(12,10),
(13,11),
(14,12),
(15,13),
(2,14),
(3,15),
(4,16),
(5,17),
(6,18),
(8,19),
(9,20),
(11,21),
(13,22),
(14,23)



SET IDENTITY_INSERT event.EventTypes ON 

insert into event.EventTypes (EventTypeID, EventType) values
(13, 'Roadside')

SET IDENTITY_INSERT event.EventTypes OFF



INSERT INTO Event.EventCategories (EventCategory) VALUES
('Sales'),
('Service'),
('TestDrive'),
('Roadside')

INSERT INTO Event.EventTypeCategories (EventTypeID, EventCategoryID) VALUES
(1, 1),
(2, 2),
(3, 2),
(7, 1),
(8, 1),
(9, 1),
(10, 2),
(11, 3),
(13, 4)





/* TODO */


