CREATE VIEW Event.vwDA_AutomotiveEventBasedInterviews

AS

SELECT
	0 AS CaseStatusTypeID, 
	EventID, 
	PartyID, 
	VehicleRoleTypeID, 
	VehicleID, 
	0 AS ModelRequirementID, 
	0 AS SelectionRequirementID
FROM Event.AutomotiveEventBasedInterviews

