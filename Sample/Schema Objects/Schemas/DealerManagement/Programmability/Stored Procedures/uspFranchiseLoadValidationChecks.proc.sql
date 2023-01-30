CREATE PROCEDURE [DealerManagement].[uspFranchiseLoadValidationChecks]
AS

SET NOCOUNT ON

/*

		Version		Created			Author			Description	
		-------		-------			------			-------			
LIVE	1.0			2021-01-29		Chris Ledger	SP to Run Franchise Load Validation Checks
LIVE	1.1			2021-02-01		Chris Ledger	Add comments to complicated query
LIVE	1.2			2021-02-11		Chris Ledger	Add reindex of DealerManagement.Franchises_Load table
LIVE	1.3			2021-02-18		Chris Ledger	Add reindex of dbo.Franchises table and clear IP_DataValidiated & IP_ProcessedDate fields
LIVE	1.4			2021-02-24		Chris Ledger	Change position of reindexing of DealerManagement.Franchises_Load table
LIVE	1.5			2021-08-18		Chris Ledger	Task 580 - Add Approved Pre-Owned FranchiseType and tidy CASE statements
LIVE	1.6			2021-08-19		Chris Ledger	Task 580 - Hard code SalesZone & SalesZoneCode for UK Approved Pre-Owned FranchiseType
LIVE	1.7			2021-11-10		Chris Ledger	Task 692 - Hard code FL_CountryID for Cyprus FranchiseCICode = '10001' to North Cyprus
LIVE	1.8			2022-01-19		Chris Ledger	Task 728 - Hard code FL_CountryID to Russian Federation for FranchiseCountry Armenia, Belarus and Kazakhstan
LIVE	1.9			2022-06-30		Chris Ledger	Task 946 - Undo hard coding for Armenia and Kazakhstan
*/

-----------------------------------------------------------------------------------------------------------------------------
-- V1.3 REINDEX dbo.Franchises table
------------------------------------------------------------------------------------------------------------------------------
ALTER INDEX ALL ON dbo.Franchises REBUILD
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
-- V1.3 Clear IP_DataValidiated & IP_ProcessedDate fields
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL SET FL.IP_DataValidated = 0, FL.IP_ProcessedDate = NULL
FROM DealerManagement.Franchises_Load FL
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- UPDATE IP_ManufacturerPartyID, IP_CountryID & IP_LanguageID
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL 
SET FL.IP_ManufacturerPartyID = B.ManufacturerPartyID,
	FL.IP_CountryID = C.CountryID,
	FL.IP_LanguageID = L.LanguageID
FROM DealerManagement.Franchises_Load FL
	LEFT JOIN dbo.Brands B ON FL.Brand = B.Brand
	LEFT JOIN ContactMechanism.Countries C ON FL.FranchiseCountryCode = C.ISOAlpha2
	LEFT JOIN dbo.Languages L ON FL.LocalLanguage1 = L.Language
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- V1.7 Hard code FL_CountryID for Cyprus FranchiseCICode = '10001' to North Cyprus
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL 
SET FL.IP_CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'North Cyprus')
FROM DealerManagement.Franchises_Load FL
	INNER JOIN ContactMechanism.Countries C ON FL.FranchiseCountryCode = C.ISOAlpha2
WHERE C.Country = 'Cyprus'
	AND FL.FranchiseCICode = '10001'
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- V1.8 Hard code FL_CountryID to Russian Federation for FranchiseCountry Armenia, Belarus and Kazakhstan
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL 
SET FL.IP_CountryID = (SELECT CountryID FROM ContactMechanism.Countries WHERE Country = 'Russian Federation')
FROM DealerManagement.Franchises_Load FL
	INNER JOIN ContactMechanism.Countries C ON FL.FranchiseCountryCode = C.ISOAlpha2
WHERE C.Country = 'Belarus'			-- V1.9
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- UPDATE IP_OutletPartyID, IP_ContactMechanismID, IP_ImporterPartyID
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL 
SET	FL.IP_OutletPartyID = F.OutletPartyID, 
	FL.IP_ContactMechanismID = F.ContactMechanismID,
	FL.IP_ImporterPartyID = F.ImporterPartyID
FROM DealerManagement.Franchises_Load FL
	INNER JOIN dbo.FranchiseTypes FT ON FL.FranchiseType = FT.FranchiseType
	INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
	INNER JOIN dbo.Franchises F ON FL.[10CharacterCode] = F.[10CharacterCode]
									AND FL.IP_CountryID = F.CountryID
									AND FTOF.OutletFunctionID = F.OutletFunctionID
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- V1.6 Hard code SalesZone & SalesZoneCode for UK Approved Pre-Owned FranchiseType
------------------------------------------------------------------------------------------------------------------------------
UPDATE FL 
SET FL.SalesZone = CASE B.Brand	WHEN 'Jaguar' THEN 'APO Jaguar Zone'
								WHEN 'Land Rover' THEN 'APO Land Rover Zone' END,
	FL.SalesZoneCode = CASE B.Brand	WHEN 'Jaguar' THEN 'APOJ'
									WHEN 'Land Rover' THEN 'APOLR' END
FROM DealerManagement.Franchises_Load FL
	INNER JOIN dbo.Brands B ON FL.Brand = B.Brand
	INNER JOIN ContactMechanism.Countries C ON FL.FranchiseCountryCode = C.ISOAlpha2
WHERE C.Country = 'United Kingdom'
	AND FL.FranchiseType = 'Approved Pre-Owned'
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- V1.2 V1.4 REINDEX DealerManagement.Franchises_Load table
------------------------------------------------------------------------------------------------------------------------------
ALTER INDEX ALL ON DealerManagement.Franchises_Load REBUILD
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
-- SET IP_DataValidated TO 1 BASED ON VALIDATION CHECKS
------------------------------------------------------------------------------------------------------------------------------
;WITH CTE_AllFranchises AS					-- Select all franchise combinations by 10CharacterCode, CountryID & FranchiseType from either Franchises_Load or Franchises tables 
(
	SELECT FL.IP_ID, 
		COALESCE(FL.IP_CountryID, F.CountryID) AS CountryID, 
		COALESCE(FL.[10CharacterCode], F.[10CharacterCode]) AS [10CharacterCode], 
		COALESCE(FL.FranchiseType, F.FranchiseType) AS FranchiseType
	FROM DealerManagement.Franchises_Load FL
	FULL OUTER JOIN dbo.Franchises F ON FL.[10CharacterCode] = F.[10CharacterCode]
									AND FL.IP_CountryID = F.CountryID
									AND FL.FranchiseType = F.FranchiseType
	WHERE COALESCE(FL.IP_ManufacturerPartyID, F.ManufacturerPartyID) IS NOT NULL											-- ManufacturerPartyID Check
		AND COALESCE(FL.[10CharacterCode], F.[10CharacterCode]) LIKE '%' + COALESCE(FL.FranchiseCICode, F.FranchiseCICode)	-- Relationship between [10CharacterCode] and FranchiseCICode
	GROUP BY FL.IP_ID, 
		COALESCE(FL.IP_CountryID, F.CountryID), 
		COALESCE(FL.[10CharacterCode],F.[10CharacterCode]), 
		COALESCE(FL.FranchiseType, F.FranchiseType)
)
, CTE_10CharacterCodesCount AS				-- Count records by 10CharacterCode
(
	SELECT AF.CountryID, 
		AF.[10CharacterCode], 
		COUNT(*) AS COUNT
	FROM CTE_AllFranchises AF
	GROUP BY AF.CountryID, 
		AF.[10CharacterCode]
)
, CTE_AllFranchisesWithCount AS				-- Select all franchises with count of 10CharacterCode included
(
	SELECT AF.IP_ID, 
		AF.CountryID, 
		AF.[10CharacterCode], 
		AF.FranchiseType, 
		M10.COUNT
	FROM CTE_AllFranchises AF
		INNER JOIN CTE_10CharacterCodesCount M10 ON AF.[10CharacterCode] = M10.[10CharacterCode]
													AND AF.CountryID = M10.CountryID
)
, CTE_MultipleFranchises AS					-- Select franchises with multiple FranchiseTypes with different FranchiseTypes shown on same row 
(
	SELECT AFC1.IP_ID AS IP_ID1, 
		AFC2.IP_ID AS IP_ID2, 
		AFC1.CountryID, 
		AFC1.[10CharacterCode], 
		AFC1.FranchiseType AS FranchiseType1, 
		AFC2.FranchiseType AS FranchiseType2, 
		AFC1.COUNT 
	FROM CTE_AllFranchisesWithCount AFC1
		INNER JOIN CTE_AllFranchisesWithCount AFC2 ON AFC1.CountryID = AFC2.CountryID
														AND AFC1.[10CharacterCode] = AFC2.[10CharacterCode]
														--AND AFC1.FranchiseType <> AFC2.FranchiseType
														AND ISNULL(AFC1.IP_ID,0) < ISNULL(AFC2.IP_ID,0)
	WHERE AFC1.COUNT > 1
)
, CTE_Valid AS								-- Determine validity of multiple franchises
(
	SELECT 
			MF.CountryID,
			MF.[10CharacterCode],
			MF.COUNT,
			CASE	WHEN MF.COUNT > 2 THEN 'More than 2 Franchise Types'
					ELSE CASE	WHEN MF.FranchiseType1 = MF.FranchiseType2 THEN 'Duplicate Franchise Types'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Sales Retailer' THEN 'Authorised Repairer / Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Satellite Sales Retailer' THEN 'Authorised Repairer / Satellite Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Authorised Bodyshop' THEN 'Authorised Repairer / Authorised Bodyshop'
								WHEN MF.FranchiseType1 = 'Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Sales Retailer'
								WHEN MF.FranchiseType1 = 'Satellite Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Satellite Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Bodyshop' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Authorised Bodyshop'
								ELSE MF.FranchiseType1 + ' / ' + MF.FranchiseType2  
								END 
					END AS Combination,
			CASE	WHEN MF.COUNT > 2 THEN 'No'
					ELSE CASE	WHEN MF.FranchiseType1 = MF.FranchiseType2 THEN 'No'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Sales Retailer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Satellite Sales Retailer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Authorised Bodyshop' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Satellite Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Bodyshop' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								ELSE 'No'
								END 
					END AS Valid
	FROM CTE_MultipleFranchises MF
	GROUP BY 
			MF.CountryID,
			MF.[10CharacterCode],
			MF.COUNT,
			CASE	WHEN MF.COUNT > 2 THEN 'More than 2 Franchise Types'
					ELSE CASE	WHEN MF.FranchiseType1 = MF.FranchiseType2 THEN 'Duplicate Franchise Types'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Sales Retailer' THEN 'Authorised Repairer / Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Satellite Sales Retailer' THEN 'Authorised Repairer / Satellite Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Authorised Bodyshop' THEN 'Authorised Repairer / Authorised Bodyshop'
								WHEN MF.FranchiseType1 = 'Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Sales Retailer'
								WHEN MF.FranchiseType1 = 'Satellite Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Satellite Sales Retailer'
								WHEN MF.FranchiseType1 = 'Authorised Bodyshop' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Authorised Repairer / Authorised Bodyshop'
								ELSE MF.FranchiseType1 + ' / ' + MF.FranchiseType2  
								END 
					END,
			CASE	WHEN MF.COUNT > 2 THEN 'No'
					ELSE CASE	WHEN MF.FranchiseType1 = MF.FranchiseType2 THEN 'No'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Sales Retailer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Satellite Sales Retailer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Repairer' AND MF.FranchiseType2 = 'Authorised Bodyshop' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Satellite Sales Retailer' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								WHEN MF.FranchiseType1 = 'Authorised Bodyshop' AND MF.FranchiseType2 = 'Authorised Repairer' THEN 'Yes'
								ELSE 'No'
								END 
					END
)
, CTE_All AS				-- Add records with only one FranchiseType to those with multiple FranchiseTypes 
(
	SELECT 
		FL.IP_ID, 
		FL.[10CharacterCode], 
		FL.FranchiseType, 
		V.Combination, 
		V.Valid
	FROM DealerManagement.Franchises_Load FL
		INNER JOIN CTE_Valid V ON FL.[10CharacterCode] = V.[10CharacterCode]
									AND FL.IP_CountryID = V.CountryID
	UNION
	SELECT 
		FL.IP_ID, 
		FL.[10CharacterCode], 
		FL.FranchiseType, 
		'Single Franchise Type' AS Combination, 
		CASE	WHEN FTOF.OutletFunctionID IS NULL THEN 'No'									-- Check on valid FranchiseTypes
				ELSE 'Yes' END AS Valid
	FROM DealerManagement.Franchises_Load FL
		LEFT JOIN CTE_AllFranchisesWithCount AFC ON FL.[10CharacterCode] = AFC.[10CharacterCode]
													AND FL.IP_CountryID = AFC.CountryID
		LEFT JOIN dbo.FranchiseTypes FT ON FL.FranchiseType = FT.FranchiseType
		LEFT JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
	WHERE AFC.COUNT = 1
)
UPDATE FL SET FL.IP_DataValidated = 1
FROM DealerManagement.Franchises_Load FL
	LEFT JOIN CTE_All A ON FL.IP_ID = A.IP_ID
	LEFT JOIN (	SELECT DISTINCT IP_ID FROM DealerManagement.Franchises_Load FL1				-- Check on existing BrandMarketQuestionnaireMetadata info
					INNER JOIN dbo.FranchiseTypes FT ON FL1.FranchiseType = FT.FranchiseType
					INNER JOIN dbo.FranchiseTypesOutletFunctions FTOF ON FT.FranchiseTypeID = FTOF.FranchiseTypeID
					INNER JOIN dbo.Markets M ON FL1.IP_CountryID = M.CountryID
					INNER JOIN dbo.Brands B ON FL1.Brand = B.Brand
					INNER JOIN dbo.BrandMarketQuestionnaireMetadata QM ON QM.BrandID = B.BrandID
																		AND QM.MarketID = M.MarketID
																		AND QM.QuestionnaireID = FTOF.QuestionnaireID) BMQ ON FL.IP_ID = BMQ.IP_ID
WHERE ISNULL(A.Valid,'No') = 'Yes'				-- Records whick are not in CTE_All are not valid
	AND BMQ.IP_ID IS NOT NULL					-- As are records without existing BrandMarketQuestionnaireMetadata info
------------------------------------------------------------------------------------------------------------------------------

GO

