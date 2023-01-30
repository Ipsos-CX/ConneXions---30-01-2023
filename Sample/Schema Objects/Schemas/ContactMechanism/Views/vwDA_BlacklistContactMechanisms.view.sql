CREATE VIEW ContactMechanism.vwDA_BlacklistContactMechanisms

AS

SELECT 
	CONVERT(BIGINT, 0) AS AuditItemID,
	BCM.ContactMechanismID,
	BCM.ContactMechanismTypeID,
	BCM.BlacklistStringID,
	BCM.FromDate
FROM ContactMechanism.ContactMechanisms CM
INNER JOIN ContactMechanism.BlacklistContactMechanisms BCM ON CM.ContactMechanismID = BCM.ContactMechanismID


