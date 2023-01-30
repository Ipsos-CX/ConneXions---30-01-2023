CREATE VIEW Load.vwEmailAddresses

AS	

/*
	Purpose:	Used to Load Email Addresses
	
	Version			Date			Developer			Comment
	1.0				2015-01-01							Created
	1.1				2020-02-11		Chris Ledger		BUG 16936 - Trim leading/trailing spaces from email addresses.

*/

	-- EmailAddress
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSEmailAddressID, 0) AS ContactMechanismID, 
		LTRIM(RTRIM(EmailAddress)) AS EmailAddress,										-- V1.1
		CHECKSUM(ISNULL(LTRIM(RTRIM(EmailAddress)), '')) AS EmailAddressChecksum,		-- V1.1
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address') AS ContactMechanismTypeID,
		CONVERT(BIT, 1) AS Valid, 
		'EmailAddress' AS EmailAddressType
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(EmailAddress)), '') IS NOT NULL

	-- PrivEmailAddress
	UNION
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSPrivEmailAddressID, 0), 
		LTRIM(RTRIM(PrivEmailAddress)),													-- V1.1			
		CHECKSUM(ISNULL(LTRIM(RTRIM(PrivEmailAddress)), '')),							-- V1.1
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'E-mail address'),
		CONVERT(BIT, 1), 
		'PrivEmailAddress'
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(PrivEmailAddress)), '') IS NOT NULL

