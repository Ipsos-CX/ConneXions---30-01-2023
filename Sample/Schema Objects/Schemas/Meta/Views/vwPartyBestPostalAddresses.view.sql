CREATE VIEW Meta.vwPartyBestPostalAddresses

AS

SELECT 
	PCM.PartyID, 
	MAX(PCM.ContactMechanismID) AS ContactMechanismID
FROM ContactMechanism.PartyContactMechanisms PCM
INNER JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
INNER JOIN ContactMechanism.PostalAddresses PA ON CM.ContactMechanismID = PA.ContactMechanismID
WHERE CM.Valid = 1
AND CASE PA.CountryID
	WHEN (SELECT CountryID FROm ContactMechanism.Countries WHERE Country = 'Italy') THEN NULLIF(RTRIM(LTRIM(PA.Street)), '')
	ELSE ''
END IS NOT NULL
-- Check Non-solicitation doesn't exist for this ContactMechanism 
AND NOT EXISTS (
	SELECT NS.NonSolicitationID
	FROM dbo.Nonsolicitations NS 
	INNER JOIN ContactMechanism.NonSolicitations CMNS ON CMNS.NonSolicitationID = NS.NonSolicitationID
													AND CMNS.ContactMechanismID = PCM.ContactMechanismID
	WHERE NS.PartyID = PCM.PartyID 
	AND ( NS.FromDate < GETDATE() OR FromDate IS NULL ) 
	AND ( NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL )
)
-- Check Non-solicitation doesn't exist for this ContactMechanismType
AND NOT EXISTS (
	SELECT NS.NonSolicitationID
	FROM dbo.Nonsolicitations NS 
	INNER JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMNTS ON CMNTS.NonSolicitationID = NS.NonSolicitationID
													AND CMNTS.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Postal Address')
	WHERE NS.PartyID = PCM.PartyID 
	AND ( NS.FromDate < GETDATE() OR FromDate IS NULL ) 
	AND ( NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL )
)
-- Check Non-solicitation doesn't exist for this Party
AND NOT EXISTS (
	SELECT NS.NonSolicitationID
	FROM dbo.NonSolicitations NS 
	INNER JOIN Party.NonSolicitations PNS ON PNS.NonSolicitationID = NS.NonSolicitationID
	WHERE NS.PartyID = PCM.PartyID 
	AND ( NS.FromDate < GETDATE() OR FromDate IS NULL ) 
	AND ( NS.ThroughDate > GETDATE() OR NS.ThroughDate IS NULL )
) 
GROUP BY PCM.PartyID

