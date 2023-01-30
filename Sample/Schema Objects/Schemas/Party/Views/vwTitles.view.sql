CREATE VIEW Party.vwTitles
AS
	SELECT
		T.TitleID, 
		T.Title, 
		TV.TitleVariationID,
		CHECKSUM(TV.TitleVariation) AS TitleChecksum, 
		TV.TitleVariation
	FROM Party.Titles T
	JOIN Party.TitleVariations TV ON T.TitleID = TV.TitleID







