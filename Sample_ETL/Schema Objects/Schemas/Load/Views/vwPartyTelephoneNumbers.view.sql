CREATE   VIEW Load.vwPartyTelephoneNumbers

AS

-- Tel

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSTelID AS ContactMechanismID, 
		MatchedODSPersonID AS PartyID, 
		CURRENT_TIMESTAMP AS FromDate, 
		CASE
			WHEN MatchedODSOrganisationID = 0 THEN (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number')
			ELSE (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number')
		END AS ContactMechanismPurposeTypeID, 
		CAST(CAST(NULL AS SMALLINT) AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSTelID > 0
	AND MatchedODSPersonID > 0
	
	UNION
	
	-- ORGANISATION
	SELECT
		AuditItemID, 
		MatchedODSTelID, 
		MatchedODSOrganisationID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main business switchboard number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSTelID > 0
	AND MatchedODSOrganisationID > 0	
	AND MatchedODSPersonID = 0
	
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSTelID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Telephone (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSTelID > 0
	AND MatchedODSPartyID > 0
	
	UNION

-- PrivTel

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSPrivTelID, 
		MatchedODSPersonID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivTelID > 0
	AND MatchedODSPersonID > 0
	
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSPrivTelID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Telephone (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivTelID > 0
	AND MatchedODSPartyID > 0
	
	UNION
	
-- BusTel

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSBusTelID, 
		MatchedODSPersonID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSBusTelID > 0
	AND MatchedODSPersonID > 0

	UNION

	-- ORGANISATION
	SELECT
		AuditItemID, 
		MatchedODSBusTelID, 
		MatchedODSOrganisationID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSBusTelID > 0
	AND MatchedODSOrganisationID > 0	
	AND MatchedODSPersonID = 0
	
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSBusTelID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Telephone (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSBusTelID > 0
	AND MatchedODSPartyID > 0
		
	UNION
	
-- MobileTel

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSMobileTelID, 
		MatchedODSPersonID, 
		CURRENT_TIMESTAMP, 
		CASE
			WHEN MatchedODSOrganisationID = 0 THEN (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private mobile number')
			ELSE (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work mobile number')
		END AS ContactMechanismPurposeTypeID, 
		CAST(CAST(NULL AS SMALLINT) AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSMobileTelID > 0
	AND MatchedODSPersonID > 0
	
	UNION	

	-- ORGANISATION
	SELECT
		AuditItemID, 
		MatchedODSMobileTelID, 
		MatchedODSOrganisationID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Business Pool Mobile Number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSMobileTelID > 0
	AND MatchedODSOrganisationID > 0	
	AND MatchedODSPersonID = 0
	
	UNION

	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSMobileTelID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Mobile (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSMobileTelID > 0
	AND MatchedODSPartyID > 0

	UNION
	
-- PrivMobileTel

	-- PERSON
	SELECT
		AuditItemID, 
		MatchedODSPrivMobileTelID, 
		MatchedODSPersonID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Private mobile number'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivMobileTelID > 0
	AND MatchedODSPersonID > 0
	
	UNION
	
	-- PARTY
	SELECT
		AuditItemID, 
		MatchedODSPrivMobileTelID, 
		MatchedODSPartyID, 
		CURRENT_TIMESTAMP, 
		(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Mobile (unknown purpose)'), 
		CAST(NULL AS SMALLINT) AS RoleTypeID
	FROM dbo.VWT
	WHERE MatchedODSPrivMobileTelID > 0
	AND MatchedODSPartyID > 0
