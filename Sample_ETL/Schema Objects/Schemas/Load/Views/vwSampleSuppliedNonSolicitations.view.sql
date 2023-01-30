
-- CGR 13-12-2016 - BUG 13364 - REMOVED AS NOW REDUNDANT CODE


--CREATE VIEW [Load].[vwSampleSuppliedNonSolicitations]
--AS

	--Purpose:	Set a case to be rejected or remove the rejection
		
	--Version			Date			Developer			Comment
	--1.0				$(ReleaseDate)	Simon Peacock		Created
	--1.1				29-05-2012		Pardip Mudhar		BUG 7005 when non-solicitaion returns null contact mechansim id for email
	--1.2				01-06-2012		Pardip Mudhar		Database name referance changed to variable



--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--PartySuppression,
	--PostalSuppression,
	--EmailSuppression, 
	--MatchedODSAddressID AS PostalContactMechanismID,
	--MatchedODSEmailAddressID AS EmailContactMechanismID
--FROM dbo.VWT
--WHERE (
	--PartySuppression = 1
	--OR ( PostalSuppression = 1 AND COALESCE ( NULLIF ( MatchedODSAddressID, 0 ) , 0 ) > 0 )
	--OR ( EmailSuppression = 1 AND EmailAddress IS NOT NULL AND ( NULLIF(MatchedODSEmailAddressID, 0) > 0 ) ) 
--)
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0

--GO