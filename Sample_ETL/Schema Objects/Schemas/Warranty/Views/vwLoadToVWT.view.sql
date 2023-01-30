CREATE VIEW Warranty.vwLoadToVWT
AS

/*

Version			Date			Developer			Comment
1.1				29/04/2014		Ali Yuksel			Bug 10289: MatchedODSModelID added 

*/

SELECT DISTINCT 
	WE.WarrantyID, 
	WE.AuditID, 
	WE.PhysicalRow AS PhysicalFileRow, 
	WE.ManufacturerID, 
	WE.SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'Warranty') AS EventTypeID,
	WE.MatchedODSVehicleID,
	V.ModelID as MatchedODSModelID, 
	WE.MatchedODSPersonID, 
	WE.MatchedODSOrganisationID, 
	WE.ServiceDealerCodeOriginatorPartyID, 
	CASE B.Brand
		WHEN 'Jaguar' THEN RTRIM(LTRIM(COALESCE(NULLIF(WE.OverseasDealerCode, ''), WE.CICode)))
		WHEN 'Land Rover' THEN RTRIM(LTRIM(ISNULL(WE.CICode, '') + NULLIF(WE.OverseasDealerCode, '')))
	END AS ServiceDealerCode, 
	WE.DateOfRepairOrig AS ServiceDateOrig, 
	WE.DateOfRepair AS ServiceDate,
	WE.CountryID
FROM Warranty.WarrantyEvents WE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = WE.ManufacturerID
INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON PCM.PartyID = COALESCE(NULLIF(WE.MatchedODSPersonID, 0), WE.MatchedODSOrganisationID)
INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
														AND CASE PA.CountryID 
																WHEN 120 THEN 20
																ELSE PA.CountryID 	
															END = WE.CountryID
LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V on V.VehicleID=WE.MatchedODSVehicleID
WHERE ISNULL(WE.AuditID, 0) > 0
AND ISNULL(WE.PhysicalRow, 0) > 0
AND ISNULL(WE.MatchedODSVehicleID, 0) > 0
AND 
(
	ISNULL(WE.MatchedODSPersonID, 0) > 0
	OR 
	ISNULL(WE.MatchedODSOrganisationID, 0) > 0
)
AND WE.DateTransferredToVWT IS NULL