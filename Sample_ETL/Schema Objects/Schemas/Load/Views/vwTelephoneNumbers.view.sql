CREATE VIEW Load.vwTelephoneNumbers

AS

--Tel
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSTelID, 0) AS ContactMechanismID, 
		Tel AS ContactNumber, 
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)') AS ContactMechanismTypeID, 
		CONVERT(BIT, 1) AS Valid, 
		'Tel' AS TelephoneType
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(Tel)), '') IS NOT NULL
--Private Tel
	UNION
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSPrivTelID, 0), 
		PrivTel,
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)'), 
		CONVERT(BIT, 1), 
		'PrivTel'
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(PrivTel)), '') IS NOT NULL
--Business Tel
	UNION
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSBusTelID, 0), 
		BusTel, 
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)'), 
		CONVERT(BIT, 1), 
		'BusTel'
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(BusTel)), '') IS NOT NULL
--Mobile Tel
	UNION
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSMobileTelID, 0), 
		MobileTel, 
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)'), 
		CONVERT(BIT, 1), 
		'MobileTel'
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(MobileTel)), '') IS NOT NULL
--Private Mobile Tel
	UNION
	SELECT 
		AuditItemID, 
		ISNULL(MatchedODSPrivMobileTelID, 0), 
		PrivMobileTel, 
		(SELECT ContactMechanismTypeID FROM [$(SampleDB)].ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)'), 
		CONVERT(BIT, 1), 
		'PrivMobileTel'
	FROM dbo.VWT
	WHERE NULLIF(LTRIM(RTRIM(PrivMobileTel)), '') IS NOT NULL
