CREATE VIEW Load.vwPartyEmailAddresses

AS

-- EmailAddress

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSEmailAddressID AS ContactMechanismID, 
		MatchedODSPersonID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		CASE
			WHEN MatchedODSOrganisationID = 0 THEN (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private e-mail address')
			ELSE (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work e-mail address')
		END AS ContactMechanismPurposeTypeID, 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE ISNULL(MatchedODSEmailAddressID, 0) > 0
	AND ISNULL(MatchedODSPersonID, 0) > 0
	
	UNION

	-- ORGANISATION
	SELECT
		AuditItemID, 
		MatchedODSEmailAddressID AS ContactMechanismID, 
		MatchedODSOrganisationID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main business e-mail address'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE ISNULL(MatchedODSEmailAddressID, 0) > 0
	AND ISNULL(MatchedODSOrganisationID, 0) > 0	
	AND ISNULL(MatchedODSPersonID, 0) = 0
		
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSEmailAddressID AS ContactMechanismID, 
		MatchedODSPartyID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'e-mail address (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSEmailAddressID > 0
	AND MatchedODSPartyID > 0
	AND ISNULL(MatchedODSPersonID, 0) = 0
	AND ISNULL(MatchedODSOrganisationID, 0) = 0

	UNION
	
-- PrivEmail

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSPrivEmailAddressID AS ContactMechanismID, 
		MatchedODSPersonID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private e-mail address'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivEmailAddressID > 0
	AND MatchedODSPersonID > 0
		
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSPrivEmailAddressID AS ContactMechanismID, 
		MatchedODSPartyID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private e-mail address'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivEmailAddressID > 0
	AND MatchedODSPartyID > 0
	AND ISNULL(MatchedODSPersonID, 0) = 0
	AND ISNULL(MatchedODSOrganisationID, 0) = 0
