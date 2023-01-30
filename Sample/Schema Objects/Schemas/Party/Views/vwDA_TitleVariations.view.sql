CREATE VIEW Party.vwDA_TitleVariations
AS
	SELECT
		CONVERT(BIGINT, 0) AS AuditItemID, 
		TitleVariationID, 
		TitleID, 
		TitleVariation
	FROM Party.TitleVariations





