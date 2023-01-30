CREATE PROCEDURE [Migration].[uspSetContactMethodologyTypeIDs]

AS

UPDATE BMQ
SET BMQ.ContactMethodologyTypeID = CCMT.ContactMethodologyTypeID
FROM dbo.BrandMarketQuestionnaireMetadata BMQ
INNER JOIN dbo.Markets M ON M.MarketID = BMQ.MarketID
INNER JOIN dbo.CountryContactMethodologyTypes CCMT ON CCMT.CountryID = M.CountryID


UPDATE dbo.BrandMarketQuestionnaireMetadata
SET ContactMethodologyTypeID = 5
WHERE SelectRoadside = 1


