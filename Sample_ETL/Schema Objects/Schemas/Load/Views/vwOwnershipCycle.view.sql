CREATE VIEW Load.vwOwnershipCycle

AS

SELECT 
	AuditItemID,
	MatchedODSEventID AS EventID, 
	OwnershipCycle,
	ODSEventTypeID AS EventTypeID
FROM dbo.VWT
WHERE MatchedODSEventID > 0	-- We have an event
AND OwnershipCycle > 0		-- Ownership Cycle provided
AND ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Sales')	-- Sales
