CREATE VIEW Event.vwDA_Events

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	E.EventID, 
	E.EventDate, 
	CONVERT(NVARCHAR(50), NULL) AS EventDateOrig,
	E.EventTypeID, 
	CONVERT(DATETIME2, NULL) AS InvoiceDate, 
	CONVERT(VARCHAR(50), NULL) AS TypeOfSaleOrig,
	VPRE.PartyID,
	VPRE.VehicleRoleTypeID,
	VPRE.VehicleID,
	CONVERT(BIGINT, 0) AS DealerID,
	VPRE.FromDate,
	VPRE.AFRLCode,
	CONVERT(VARCHAR(50), '') AS CRCCaseNumber,
	CONVERT(VARCHAR(50), '') AS LostLeadID,
	CONVERT(VARCHAR(50), '') AS LandRoverExperienceID -- TASK 879
FROM Event.Events E
	INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID

