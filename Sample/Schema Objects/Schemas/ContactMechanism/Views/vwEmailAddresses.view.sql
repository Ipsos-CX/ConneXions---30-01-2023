CREATE VIEW [ContactMechanism].[vwEmailAddresses]

AS

SELECT 
	EA.ContactMechanismID, 
	EA.EmailAddress, 
	CM.ContactMechanismTypeID,
	NS.NonSolicitationID
FROM ContactMechanism.EmailAddresses EA
INNER JOIN ContactMechanism.ContactMechanisms CM ON EA.ContactMechanismID = CM.ContactMechanismID
LEFT JOIN ContactMechanism.NonSolicitations CMNS
	INNER JOIN dbo.NonSolicitations NS ON NS.NonSolicitationID = CMNS.NonSolicitationID
					AND GETDATE() >= NS.FromDate
					AND NS.ThroughDate IS NULL
ON CMNS.ContactMechanismID = CM.ContactMechanismID
WHERE NULLIF(LTRIM(RTRIM(EA.EmailAddress)), '') IS NOT NULL

