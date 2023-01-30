
-- CGR 13-12-2016 - BUG 13364 - REMOVED AS NOW REDUNDANT CODE


--CREATE VIEW [Load].vwSampleSuppliedPhoneNonSolicitations
--AS

	--Purpose:	Provides phone numbers which require non-solicitation
		
	--Version			Date			Developer			Comment
	--1.3				29-09-2015		Chris Ross			Created (as part of BUG 11387)



--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--MatchedODSTelID AS TelephoneContactMechanismID
--FROM dbo.VWT
--WHERE ( PhoneSuppression = 1 AND Tel IS NOT NULL AND ( NULLIF(MatchedODSTelID, 0) > 0 ) ) 
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0

--UNION

--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--MatchedODSPrivTelID AS TelephoneContactMechanismID
--FROM dbo.VWT
--WHERE ( PhoneSuppression = 1 AND PrivTel IS NOT NULL AND ( NULLIF(MatchedODSPrivTelID, 0) > 0 ) ) 
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0


--UNION

--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--MatchedODSBusTelID AS TelephoneContactMechanismID
--FROM dbo.VWT
--WHERE ( PhoneSuppression = 1 AND BusTel IS NOT NULL AND ( NULLIF(MatchedODSBusTelID, 0) > 0 ) ) 
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0


--UNION

--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--MatchedODSMobileTelID AS TelephoneContactMechanismID
--FROM dbo.VWT
--WHERE ( PhoneSuppression = 1 AND MobileTel IS NOT NULL AND ( NULLIF(MatchedODSMobileTelID, 0) > 0 ) ) 
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0




--UNION

--SELECT
	--AuditItemID, 
	--0 AS NonSolicitationID,
	--(SELECT NonSolicitationTextID FROM [$(SampleDB)].dbo.NonSolicitationTexts WHERE NonSolicitationText = 'Client Provided Non Solicitation') AS NonSolicitationTextID, 
	--COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	--NULL AS RoleTypeID, 
	--GETDATE() AS FromDate, 
	--CAST(NULL AS DATETIME2) AS ThroughDate, 
	--'Sample Supplied Non Solicitation' AS Notes,
	--MatchedODSPrivMobileTelID AS TelephoneContactMechanismID
--FROM dbo.VWT
--WHERE ( PhoneSuppression = 1 AND PrivMobileTel IS NOT NULL AND ( NULLIF(MatchedODSPrivMobileTelID, 0) > 0 ) ) 
--AND COALESCE( 
		--NULLIF(MatchedODSPersonID, 0), 
		--NULLIF(MatchedODSOrganisationID, 0), 
		--NULLIF(MatchedODSPartyID, 0), 0) > 0


--GO