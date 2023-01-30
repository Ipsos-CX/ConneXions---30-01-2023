CREATE VIEW ContactMechanism.vwDA_ContactMechanismNonSolicitations

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	NS.NonSolicitationID,
	NS.NonSolicitationTextID, 
	NS.PartyID, 
	NS.RoleTypeID, 
	NS.FromDate, 
	NS.ThroughDate, 
	NS.Notes,
	CMNS.ContactMechanismID,
	NS.HardSet
FROM dbo.NonSolicitations NS 
INNER JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID


