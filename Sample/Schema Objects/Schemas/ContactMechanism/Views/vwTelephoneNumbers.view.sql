CREATE VIEW ContactMechanism.vwTelephoneNumbers

AS

SELECT 
	TN.ContactMechanismID, 
	TN.ContactNumber, 
	CMT.ContactMechanismType,
	CMT.ContactMechanismTypeID
FROM ContactMechanism.TelephoneNumbers TN
INNER JOIN ContactMechanism.ContactMechanisms CM ON TN.ContactMechanismID = CM.ContactMechanismID
INNER JOIN ContactMechanism.ContactMechanismTypes CMT ON CM.ContactMechanismTypeID = CMT.ContactMechanismTypeID
WHERE NULLIF(LTRIM(RTRIM(TN.ContactNumber)), '') IS NOT NULL