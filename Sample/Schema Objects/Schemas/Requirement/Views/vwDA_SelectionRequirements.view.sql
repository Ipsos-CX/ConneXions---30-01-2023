CREATE VIEW Requirement.vwDA_SelectionRequirements

AS

SELECT
	RequirementID,
	SelectionDate,
	SelectionStatusTypeID,
	SelectionTypeID,
	DateLastRun,
	RecordsSelected,
	RecordsRejected,
	LastViewedDate,
	LastViewedPartyID,
	LastViewedRoleTypeID,
	DateOutputAuthorised,
	AuthorisingPartyID,
	AuthorisingRoleTypeID,
	CONVERT(BIGINT, 0) AS AuditItemID
FROM Requirement.SelectionRequirements


