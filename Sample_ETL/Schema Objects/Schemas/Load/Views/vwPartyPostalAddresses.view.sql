CREATE VIEW Load.vwPartyPostalAddresses

AS

-- PEOPLE
SELECT
	AuditItemID, 
	VWTID, 
	MatchedODSAddressID AS ContactMechanismID, 
	MatchedODSPersonID AS PartyID, 
	CURRENT_TIMESTAMP AS FromDate, 
	CASE MatchedODSOrganisationID -- IF WE HAVE BEEN GIVEN COMPANY DETAILS THEN SET THE ADDRESS TO BE A WORK ADDRESS, OTHERWISE A HOME ADDRESS
		WHEN 0 THEN (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home address')
		ELSE (SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work address')
	END AS ContactMechanismPurposeTypeID, 
	CAST(NULL AS SMALLINT) AS RoleTypeID
FROM dbo.VWT
WHERE MatchedODSAddressID > 0
AND MatchedODSPersonID > 0

UNION

-- ORGANISATIONS
SELECT
	AuditItemID, 
	VWTID, 
	MatchedODSAddressID AS ContactMechanismID, 
	MatchedODSOrganisationID AS PartyID, 
	CURRENT_TIMESTAMP AS FromDate, 
	(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main business address') AS ContactMechanismPurposeTypeID,
	CAST(NULL AS SMALLINT) AS RoleTypeID
FROM dbo.VWT
WHERE MatchedODSAddressID > 0
AND MatchedODSOrganisationID > 0

UNION

-- PARTIES
SELECT
	AuditItemID, 
	VWTID, 
	MatchedODSAddressID AS ContactMechanismID, 
	MatchedODSPartyID AS PartyID, 
	CURRENT_TIMESTAMP AS FromDate, 
	(SELECT ContactMechanismPurposeTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Unknown Purpose') AS ContactMechanismPurposeTypeID,
	CAST(NULL AS SMALLINT) AS RoleTypeID
FROM dbo.VWT
WHERE MatchedODSAddressID > 0
AND MatchedODSPartyID > 0
AND ISNULL(MatchedODSOrganisationID, 0) = 0
AND ISNULL(MatchedODSPersonID, 0) = 0





















