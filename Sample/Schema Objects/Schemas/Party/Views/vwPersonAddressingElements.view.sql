CREATE VIEW [Party].[vwPersonAddressingElements]

AS

/*
Version		Created			Author			History		
1.1			2021-07-15		Chris Ledger	Task 555: Changed view to exclude Required elements for AddressingTypeID = 2
*/

SELECT E.AddressElement, E.OrdinalPosition, E.PersonAddressingPatternID, P.AddressingTypeID, P.QuestionnaireRequirementID
FROM Party.PersonAddressingElements E
INNER JOIN Party.PersonAddressingPatterns P ON P.PersonAddressingPatternID = E.PersonAddressingPatternID

UNION

SELECT AddressElement, OrdinalPosition, 0 AS PersonAddressingPatternID, AddressingTypeID, QuestionnaireRequirementID
FROM Party.AddressingPatternDefaultElements
WHERE Required = 1
	AND AddressingTypeID <> 2	-- V1.1