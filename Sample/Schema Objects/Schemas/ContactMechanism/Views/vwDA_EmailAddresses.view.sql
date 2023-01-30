CREATE VIEW ContactMechanism.vwDA_EmailAddresses

AS

SELECT
	CONVERT(BIGINT, 0) AS AuditItemID, 
	EA.ContactMechanismID, 
	EA.EmailAddress, 
	EA.EmailAddressChecksum,
	CM.ContactMechanismTypeID, 
	CM.Valid, 
	CONVERT(VARCHAR(25), '') AS EmailAddressType
FROM ContactMechanism.EmailAddresses EA
INNER JOIN ContactMechanism.ContactMechanisms CM ON CM.ContactMechanismID = EA.ContactMechanismID











