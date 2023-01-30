CREATE VIEW ContactMechanism.vwDA_TelephoneNumbers

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	TN.ContactMechanismID, 
	TN.ContactNumber, 
	CM.ContactMechanismTypeID, 
	CM.Valid, 
	CONVERT(VARCHAR(100), '') AS TelephoneType
FROM ContactMechanism.TelephoneNumbers TN
INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = TN.ContactMechanismID
