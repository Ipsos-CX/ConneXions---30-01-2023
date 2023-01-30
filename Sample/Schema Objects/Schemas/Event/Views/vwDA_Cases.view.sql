CREATE VIEW [Event].[vwDA_Cases]
AS 

	SELECT 
		CONVERT(BIGINT, 0) AS AuditItemID
		, C.CaseID
		, AEBI.PartyID
		, C.CaseStatusTypeID
		, C.CreationDate
		, CONVERT(VARCHAR(10), '') AS ClosureDateOrig
		, C.ClosureDate
		, C.OnlineExpiryDate
		, C.SelectionOutputPassword
		, C.AnonymityDealer
		, C.AnonymityManufacturer
	FROM Event.Cases C
	INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON C.CaseID = AEBI.CaseID