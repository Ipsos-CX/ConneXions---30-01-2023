CREATE VIEW ContactMechanism.vwDA_PartyContactMechanismPurposes

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	ContactMechanismID, 
	PartyID, 
	ContactMechanismPurposeTypeID, 
	FromDate
FROM ContactMechanism.PartyContactMechanismPurposes

