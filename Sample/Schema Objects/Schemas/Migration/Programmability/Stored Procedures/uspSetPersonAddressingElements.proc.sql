CREATE PROCEDURE [Migration].[uspSetPersonAddressingElements]

AS
CREATE TABLE #PersonAddressingElements
(
   [PersonAddressingPatternID] INT           NOT NULL,
    [OrdinalPosition]           TINYINT       NOT NULL,
    [AddressElement]            NVARCHAR (50) NULL
)

INSERT INTO #PersonAddressingElements
SELECT DISTINCT PAP.PersonAddressingPatternID, E.OrdinalPosition, LTRIM(RTRIM(ElementDesc)) AS AddressElement
FROM Party.PersonAddressingPatterns PAP
INNER JOIN [Prophet-ODS].dbo.PersonAddressingPatterns L ON L.RequirementID = PAP.QuestionnaireRequirementID
														AND L.AddressingPatternTypeID = PAP.AddressingTypeID
INNER JOIN [Prophet-ODS].dbo.PersonTitleAddressingPatterns T ON T.AddressingPatternID = L.AddressingPatternID
														AND T.RequirementID = L.RequirementID
														AND T.PreNominalTitleID = PAP.TitleID
INNER JOIN [Prophet-ODS].dbo.AddressingPatternElements E ON E.AddressingPatternID = L.AddressingPatternID
														AND E.Required = 1
INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = PAP.QuestionnaireRequirementID


UPDATE #PersonAddressingElements
SET AddressElement = 'Dear'
WHERE AddressElement = '@AddressingGreeting'

UPDATE #PersonAddressingElements
SET AddressElement = '@Title'
WHERE AddressElement = '@PreNom'

UPDATE #PersonAddressingElements
SET AddressElement = '@TitleENGToBRA'
WHERE AddressElement = '@PreNomENGToBRA'

UPDATE #PersonAddressingElements
SET AddressElement = '@TitleHerrToHerrn'
WHERE AddressElement = '@PreNomHerrToHerrn'

DELETE FROM #PersonAddressingElements
WHERE PersonAddressingPatternID = 107
ANd AddressElement = 'Sehr geehrte Frau Magister'

DELETE FROM #PersonAddressingElements
WHERE PersonAddressingPatternID = 108
ANd AddressElement = 'Sehr geehrter Herr Magister'

DELETE FROM #PersonAddressingElements
WHERE PersonAddressingPatternID = 1476
ANd AddressElement IN ('Frau Magister', 'Herr Magister')

DELETE FROM #PersonAddressingElements
WHERE PersonAddressingPatternID = 1477
ANd AddressElement IN ('@TitleHerrToHerrn', 'Frau Magister')

DELETE FROM #PersonAddressingElements
WHERE PersonAddressingPatternID = 1478
ANd AddressElement IN ('@TitleHerrToHerrn', 'Herr Magister')


DELETE E
FROM #PersonAddressingElements E
INNER JOIN Party.PersonAddressingPatterns PAP ON PAP.PersonAddressingPatternID = E.PersonAddressingPatternID
WHERE E.PersonAddressingPatternID IN (
	SELECT PersonAddressingPatternID
	FROM #PersonAddressingElements
	GROUP BY PersonAddressingPatternID, OrdinalPosition
	HAVING COUNT(*) > 1
)
AND E.AddressElement = 'Monsieur'
AND PAP.Pattern = 'Madame'

DELETE E
FROM #PersonAddressingElements E
INNER JOIN Party.PersonAddressingPatterns PAP ON PAP.PersonAddressingPatternID = E.PersonAddressingPatternID
WHERE E.PersonAddressingPatternID IN (
	SELECT PersonAddressingPatternID
	FROM #PersonAddressingElements
	GROUP BY PersonAddressingPatternID, OrdinalPosition
	HAVING COUNT(*) > 1
)
AND E.AddressElement = 'Madame'
AND PAP.Pattern = 'Monsieur'

DELETE E
FROM #PersonAddressingElements E
INNER JOIN Party.PersonAddressingPatterns PAP ON PAP.PersonAddressingPatternID = E.PersonAddressingPatternID
WHERE E.PersonAddressingPatternID IN (
	SELECT PersonAddressingPatternID
	FROM #PersonAddressingElements
	GROUP BY PersonAddressingPatternID, OrdinalPosition
	HAVING COUNT(*) > 1
)
AND E.AddressElement = 'M. le Docteur'
AND PAP.Pattern LIKE 'Mme%'

DELETE E
FROM #PersonAddressingElements E
INNER JOIN Party.PersonAddressingPatterns PAP ON PAP.PersonAddressingPatternID = E.PersonAddressingPatternID
WHERE E.PersonAddressingPatternID IN (
	SELECT PersonAddressingPatternID
	FROM #PersonAddressingElements
	GROUP BY PersonAddressingPatternID, OrdinalPosition
	HAVING COUNT(*) > 1
)
AND E.AddressElement = 'Mme le Docteur'
AND PAP.Pattern LIKE 'M. le%'


INSERT INTO Party.PersonAddressingElements
SELECT DISTINCT PersonAddressingPatternID, OrdinalPosition, AddressElement
FROM #PersonAddressingElements


DROP TABLE #PersonAddressingElements



-- ADD THE DEFAULTS
INSERT INTO [Party].[AddressingPatternDefaults]
VALUES (1, '@Title @LastName'),
(2, '@Title @FirstName/@Initials @LastName @SecondLastName')






CREATE TABLE #Elements (
	AddressingTypeID INT,
	OrdinalPosition TINYINT,
	AddressElement NVARCHAR(50)
)
	
INSERT INTO #Elements
VALUES (1, 1, '@AddressingGreeting'),
(1, 2, '@Title'),
(1, 3, '@LastName'),
(2, 1, '@Title'),
(2, 2, '@FirstName/@Initials'),
(2, 3, '@LastName'),
(2, 4, '@SecondLastName')


SELECT DISTINCT QuestionnaireRequirementID
INTO #QR
FROM dbo.vwBrandMarketQuestionnaireSampleMetadata

INSERT INTO [Party].[AddressingPatternDefaultElements]
SELECT DISTINCT AddressingTypeID, OrdinalPosition, AddressElement, #QR.QuestionnaireRequirementID, 1
FROM #Elements
CROSS JOIN #QR

DELETE 
FROM [Party].[AddressingPatternDefaultElements]
WHERE AddressingTypeID = 1
AND OrdinalPosition = 1

UPDATE [Party].[AddressingPatternDefaultElements]
SET OrdinalPosition = 1
WHERE AddressingTypeID = 1
AND OrdinalPosition = 2

UPDATE [Party].[AddressingPatternDefaultElements]
SET OrdinalPosition = 2
WHERE AddressingTypeID = 1
AND OrdinalPosition = 3


UPDATE [Party].[AddressingPatternDefaultElements]
SET Required = 0
WHERE AddressingTypeID = 2
AND OrdinalPosition IN (2, 4)

