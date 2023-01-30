CREATE VIEW [Event].[vwDA_EventPartyRoles]

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	PartyID, 
	RoleTypeID, 
	EventID,
	CONVERT(VARCHAR, '') DealerCode,
	CONVERT(INT, 0)DealerCodeOriginatorPartyID
FROM Event.EventPartyRoles





