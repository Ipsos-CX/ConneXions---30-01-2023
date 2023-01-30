CREATE VIEW [Roadside].[vwLoadToVWT]

AS

/*
	Purpose:	Used to load Roadside to VWT
	
	Version			Date			Developer			Comment
	1.1				10-01-2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases												
*/

SELECT DISTINCT 
	WE.RoadsideID, 
	WE.AuditID, 
	WE.PhysicalRowID AS PhysicalFileRow, 
	WE.ManufacturerID, 
	WE.ManufacturerID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'Roadside') AS EventTypeID,
	
	WE.VIN,						-- BUG 1659 - add in Vehicle information for creation, in the case of matching on Name + Email
	WE.RegistrationNumber, 
	WE.VehicleRegistrationDateOrig,
	
	WE.MatchedODSVehicleID, 
	WE.MatchedODSPersonID, 
	WE.MatchedODSOrganisationID, 
	WE.ManufacturerID as RoadsideNetworkOriginatorPartyID, 
	WE.[Address8(Country)] as RoadsideNetworkCode,
	COALESCE(WE.BreakdownDateOrig, WE.CarHireStartDateOrig) AS RoadsideDateOrig, 
	COALESCE(WE.BreakdownDate, WE.CarHireStartDate) AS RoadsideDate,
	WE.CountryID,
	WE.BreakdownCountryID,
	--Bug 10147 --
	WE.CompleteSuppression, 
	WE.[Suppression-Email],
	WE.[Suppression-Phone],			-- BUG 15285 
	WE.[Suppression-Mail],
	--Bug 10147 --
	WE.SampleTriggeredSelectionReqID,
	--BUG 12659 --
	WE.MatchedODSEmailAddress1ID,
	WE.MatchedODSEmailAddress2ID,
	WE.PreferredLanguageID,
	-- Bug 14686 --
	WE.MatchedODSMobileTelephoneNumberID,
	WE.EmailAddress1,		-- BUG 15006
	WE.EmailAddress2		-- BUG 15006
	
FROM Roadside.RoadsideEvents WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = WE.ManufacturerID
-- BUG 11595 - Removed link to Postal Address as stopping people with no postal address being matched (i.e. for MENA).
--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = COALESCE(NULLIF(WE.MatchedODSPersonID, 0), WE.MatchedODSOrganisationID)
--INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
														--AND CASE PA.CountryID 
																--WHEN 120 THEN 20
																--ELSE PA.CountryID 	
															--END = WE.CountryID
WHERE PerformNormalVWTLoadFlag = 'N'	-- BUG 8967
AND ISNULL(WE.AuditID, 0) > 0
AND ISNULL(WE.PhysicalRowID, 0) > 0
-- AND ISNULL(WE.MatchedODSVehicleID, 0) > 0   -- BUG 12659 - Removed as we can assume we have matched on something if either PersonID or OrgID is populated
AND 
(
	ISNULL(WE.MatchedODSPersonID, 0) > 0
	OR 
	ISNULL(WE.MatchedODSOrganisationID, 0) > 0
)
AND WE.DateTransferredToVWT IS NULL
