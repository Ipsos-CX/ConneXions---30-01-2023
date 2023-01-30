CREATE VIEW [IAssistance].[vwLoadToVWT]

AS

SELECT DISTINCT 
	IE.IAssistanceID, 
	IE.AuditID, 
	IE.PhysicalRowID AS PhysicalFileRow, 
	IE.ManufacturerID, 
	IE.ManufacturerID as SampleSupplierPartyID, 
	(SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'I-Assistance') AS EventTypeID,
	
	IE.VIN,						
	IE.RegistrationNumber, 
	IE.VehicleRegistrationDateOrig,
	
	IE.MatchedODSVehicleID, 
	IE.MatchedODSPersonID, 
	IE.MatchedODSOrganisationID, 
	IE.ManufacturerID as IAssistanceCentreOriginatorPartyID, 
	IE.[Address8(Country)] as IAssistanceCentreCode,
	IE.IAssistanceCallCloseDateOrig AS IAssistanceDateOrig, 
	IE.IAssistanceCallCloseDate AS IAssistanceDate,
	IE.CountryID,
	IE.CompleteSuppression, 
	IE.[Suppression-Email],
	IE.[Suppression-Mail],
	IE.SampleTriggeredSelectionReqID,
	IE.MatchedODSEmailAddress1ID,
	IE.MatchedODSEmailAddress2ID,
	IE.PreferredLanguageID,
	IE.MatchedODSMobileTelephoneNumberID,
	IE.EmailAddress1,		
	IE.EmailAddress2		
	
FROM IAssistance.IAssistanceEvents IE
INNER JOIN [$(SampleDB)].dbo.Brands B ON B.ManufacturerPartyID = IE.ManufacturerID
WHERE IE.PerformNormalVWTLoadFlag = 'N'	
AND ISNULL(IE.AuditID, 0) > 0
AND ISNULL(IE.PhysicalRowID, 0) > 0
AND 
(
	ISNULL(IE.MatchedODSPersonID, 0) > 0
	OR 
	ISNULL(IE.MatchedODSOrganisationID, 0) > 0
)
AND IE.DateTransferredToVWT IS NULL
