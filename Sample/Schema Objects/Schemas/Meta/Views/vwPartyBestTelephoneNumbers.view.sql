CREATE VIEW Meta.vwPartyBestTelephoneNumbers

AS

SELECT
	PCM.PartyID,
	MAX(P.ContactMechanismID) AS PhoneID,
	MAX(L.ContactMechanismID) AS LandlineID,
	MAX(H.ContactMechanismID) AS HomeLandlineID,
	MAX(W.ContactMechanismID) AS WorkLandlineID,
	MAX(M.ContactMechanismID) AS MobileID
FROM ContactMechanism.PartyContactMechanisms PCM
LEFT JOIN (
	SELECT
		PCM.PartyID,
		MAX(PCM.ContactMechanismID) AS ContactMechanismID
	FROM ContactMechanism.PartyContactMechanisms PCM
	JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
	JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
	WHERE CM.Valid = 1
	AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone')
	AND NOT EXISTS (
		SELECT * 
		FROM dbo.NonSolicitations NS
		JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
		WHERE NS.PartyID = PCM.PartyID
		AND CMNS.ContactMechanismID = PCM.ContactMechanismID
		AND GETDATE() >= NS.FromDate
		AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
	)
	GROUP BY PCM.PartyID
) P ON P.ContactMechanismID = PCM.ContactMechanismID AND P.PartyID = PCM.PartyID
LEFT JOIN (
	SELECT
		PCM.PartyID,
		MAX(PCM.ContactMechanismID) AS ContactMechanismID
	FROM ContactMechanism.PartyContactMechanisms PCM
	JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
	JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
	WHERE CM.Valid = 1
	AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
	AND NOT EXISTS (
		SELECT * 
		FROM dbo.NonSolicitations NS
		JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
		WHERE NS.PartyID = PCM.PartyID
		AND CMNS.ContactMechanismID = PCM.ContactMechanismID
		AND GETDATE() >= NS.FromDate
		AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
	)
	GROUP BY PCM.PartyID
) L ON L.ContactMechanismID = PCM.ContactMechanismID AND L.PartyID = PCM.PartyID
LEFT JOIN (
	SELECT
		PCM.PartyID,
		MAX(PCM.ContactMechanismID) AS ContactMechanismID
	FROM ContactMechanism.PartyContactMechanisms PCM
	JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
	JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
	JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.PartyID = PCM.PartyID
						AND PCMP.ContactMechanismID = PCM.ContactMechanismID
	WHERE CM.Valid = 1
	AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
	AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Main home number')
	AND NOT EXISTS (
		SELECT * 
		FROM dbo.NonSolicitations NS
		JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
		WHERE NS.PartyID = PCM.PartyID
		AND CMNS.ContactMechanismID = PCM.ContactMechanismID
		AND GETDATE() >= NS.FromDate
		AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
	)
	GROUP BY PCM.PARTYID
) H ON H.ContactMechanismID = PCM.ContactMechanismID AND H.PartyID = PCM.PartyID
LEFT JOIN (
	SELECT
		PCM.PartyID,
		MAX(PCM.ContactMechanismID) AS ContactMechanismID
	FROM ContactMechanism.PartyContactMechanisms PCM
	JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
	JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
	JOIN ContactMechanism.PartyContactMechanismPurposes PCMP ON PCMP.PartyID = PCM.PartyID
						AND PCMP.ContactMechanismID = PCM.ContactMechanismID
	WHERE CM.Valid = 1
	AND CM.ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (landline)')
	AND PCMP.ContactMechanismPurposeTypeID = (SELECT ContactMechanismPurposeTypeID FROM ContactMechanism.ContactMechanismPurposeTypes WHERE ContactMechanismPurposeType = 'Work direct dial number')
	AND NOT EXISTS (
		SELECT * 
		FROM dbo.NonSolicitations NS
		JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
		WHERE NS.PartyID = PCM.PartyID
		AND CMNS.ContactMechanismID = PCM.ContactMechanismID
		AND GETDATE() >= NS.FromDate
		AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
	)
	GROUP BY PCM.PARTYID
) W ON W.ContactMechanismID = PCM.ContactMechanismID AND W.PartyID = PCM.PartyID
LEFT JOIN (
	SELECT
		PCM.PartyID,
		MAX(PCM.ContactMechanismID) AS ContactMechanismID
	FROM ContactMechanism.PartyContactMechanisms PCM
	JOIN ContactMechanism.ContactMechanisms CM ON PCM.ContactMechanismID = CM.ContactMechanismID
	JOIN ContactMechanism.TelephoneNumbers TN ON CM.ContactMechanismID = TN.ContactMechanismID
	WHERE CM.Valid = 1
	AND ContactMechanismTypeID = (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType = 'Phone (mobile)')
	AND NOT EXISTS (
		SELECT * 
		FROM dbo.NonSolicitations NS
		JOIN ContactMechanism.NonSolicitations CMNS ON NS.NonSolicitationID = CMNS.NonSolicitationID
		WHERE NS.PartyID = PCM.PartyID
		AND CMNS.ContactMechanismID = PCM.ContactMechanismID
		AND GETDATE() >= NS.FromDate
		AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
	)
	GROUP BY PCM.PartyID
) M ON M.ContactMechanismID = PCM.ContactMechanismID AND M.PartyID = PCM.PartyID
WHERE NOT EXISTS (
	SELECT * 
	FROM dbo.NonSolicitations NS
	JOIN Party.NonSolicitations PNS ON NS.NonSolicitationID = PNS.NonSolicitationID
	WHERE NS.PartyID = PCM.PartyID
	AND GETDATE() >= NS.FromDate
	AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
)
AND NOT EXISTS (
	SELECT * 
	FROM dbo.NonSolicitations NS
	JOIN ContactMechanism.ContactMechanismTypeNonSolicitations CMTNS ON NS.NonSolicitationID = CMTNS.NonSolicitationID
	WHERE NS.PartyID = PCM.PartyID
	AND CMTNS.ContactMechanismTypeID IN (SELECT ContactMechanismTypeID FROM ContactMechanism.ContactMechanismTypes WHERE ContactMechanismType IN ('Phone', 'Phone (landline)', 'Phone (mobile)'))
	AND GETDATE() >= NS.FromDate
	AND GETDATE() <= ISNULL(NS.ThroughDate, '31 December 2999')
)
AND NOT COALESCE(	
	P.PartyID,
	L.PartyID,
	H.PartyID,
	W.PartyID,
	M.PartyID,
	0
) = 0
GROUP BY PCM.PartyID




