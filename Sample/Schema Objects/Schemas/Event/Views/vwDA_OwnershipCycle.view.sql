CREATE VIEW Event.vwDA_OwnershipCycle

AS

SELECT 
	CAST(0 AS BIGINT) AuditItemID,
	E.EventID,
	O.OwnershipCycle,
	E.EventTypeID
FROM Event.Events E
INNER JOIN Event.OwnershipCycle O on E.EventID = O.EventID




