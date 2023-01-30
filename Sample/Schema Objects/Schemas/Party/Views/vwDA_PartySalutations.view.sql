CREATE VIEW Party.vwDA_PartySalutations
AS
	SELECT
		CONVERT(BIGINT, 0) AS AuditItemID, 
		PartyID,
		Salutation
	FROM Party.PartySalutations




