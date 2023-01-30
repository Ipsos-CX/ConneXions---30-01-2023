CREATE VIEW Party.vwDA_NonSolicitations

AS

SELECT
	CONVERT(BIGINT, 0) AuditItemID, 
	NS.NonSolicitationID,
	NS.NonSolicitationTextID, 
	NS.PartyID, 
	NS.RoleTypeID, 
	NS.FromDate, 
	NS.ThroughDate, 
	NS.Notes,
	NS.HardSet
FROM dbo.NonSolicitations NS 
INNER JOIN Party.NonSolicitations PNS on NS.NonSolicitationID = PNS.NonSolicitationID

