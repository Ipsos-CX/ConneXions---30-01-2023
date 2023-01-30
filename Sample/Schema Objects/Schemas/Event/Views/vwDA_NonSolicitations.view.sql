CREATE VIEW [Event].[vwDA_NonSolicitations]
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
	ENS.EventID
FROM dbo.NonSolicitations NS 
INNER JOIN Event.NonSolicitations ENS on NS.NonSolicitationID = ENS.NonSolicitationID;