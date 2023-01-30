/*

-- CGR 13-12-2016 - REMOVED AS UNUSED CODE (After discussion with Eddie)


CREATE VIEW [Load].[vwSampleSuppliedGlobalLoaderNonSolicitations]

AS
--
	--Purpose:		Identify suppressions that need to be created as non solicitations
		
	--Version			Date			Developer			Comment
	--1.0				25/3/2015		Eddie Thomas		Derived from vwSampleSuppliedNonSolicitations  :
														--Add phone non solicitations from the Global Loader	
	
--


SELECT
	AuditItemID, 
	0 AS NonSolicitationID,
	(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	NULL AS RoleTypeID, 
	GETDATE() AS FromDate, 
	CAST(NULL AS DATETIME2) AS ThroughDate, 
	'Sample Supplied Non Solicitation' AS Notes,
	PartySuppression,
	PostalSuppression,
	EmailSuppression,
	PhoneSuppression, 
	MatchedODSAddressID AS PostalContactMechanismID,
	MatchedODSEmailAddressID AS EmailContactMechanismID,
	COALESCE(NULLIF(MatchedODSPrivTelID, 0), NULLIF(MatchedODSBusTelID, 0), NULLIF(MatchedODSMobileTelID, 0), 0) AS PhoneContactMechanismID

FROM dbo.VWT
WHERE (
	PartySuppression = 1
	OR ( PostalSuppression = 1 AND COALESCE ( NULLIF ( MatchedODSAddressID, 0 ) , 0 ) > 0 )
	OR ( EmailSuppression = 1 AND EmailAddress IS NOT NULL AND ( NULLIF(MatchedODSEmailAddressID, 0) > 0 ) ) 
	OR ( PhoneSuppression = 1 AND COALESCE(NULLIF(MatchedODSPrivTelID, 0), NULLIF(MatchedODSBusTelID, 0), NULLIF(MatchedODSMobileTelID, 0), 0) > 0)
)
AND COALESCE( 
		NULLIF(MatchedODSPersonID, 0), 
		NULLIF(MatchedODSOrganisationID, 0), 
		NULLIF(MatchedODSPartyID, 0), 0) > 0

GO

*/