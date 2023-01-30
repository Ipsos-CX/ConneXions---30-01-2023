CREATE VIEW ContactMechanism.vwDA_PartyContactMechanisms

AS

SELECT	
	CONVERT(BIGINT, 0) AS AuditItemID, 
	CM.ContactMechanismID, 
	PCM.PartyID,
	CURRENT_TIMESTAMP AS FromDate,  
	PCMP.ContactMechanismPurposeTypeID, 
	PCM.RoleTypeID
FROM ContactMechanism.ContactMechanisms CM
INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON CM.ContactMechanismID = PCM.ContactMechanismID
INNER JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCM.ContactMechanismID = PCMP.ContactMechanismID
																AND PCM.PartyID = PCMP.PartyID








