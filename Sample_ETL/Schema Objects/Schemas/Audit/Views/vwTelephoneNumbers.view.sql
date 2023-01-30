CREATE VIEW Audit.vwTelephoneNumbers

AS

SELECT DISTINCT 
	atn.ContactMechanismID, 
	atn.ContactNumber, 
	atn.ContactNumberChecksum,
	cm.ContactMechanismTypeID
FROM [$(AuditDB)].Audit.TelephoneNumbers atn
INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms cm ON cm.ContactMechanismID = atn.ContactMechanismID  ;
