CREATE PROCEDURE [Migration].[uspCorrectAddressingPatterns]

AS

-- DEFAULT VALUES
UPDATE PAP
SET PAP.GenderID = NULL
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.QuestionnaireRequirementID = Q.RequirementID
WHERE PAP.DefaultAddressing = 1

-- Jaguar Spain Sales
UPDATE PAP
SET PAP.GenderID = NULL
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN Party.Titles T ON T.TitleID = PAP.TitleID
WHERE Q.Requirement = 'Jaguar Spain Sales'

UPDATE PAP
SET PAP.GenderID = 1
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN Party.Titles T ON T.TitleID = PAP.TitleID
WHERE Q.Requirement = 'Jaguar Spain Sales'
AND PAP.AddressingTypeID = 1
AND T.TitleID IN (17, 84)

UPDATE PAP
SET PAP.GenderID = 2
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN Party.Titles T ON T.TitleID = PAP.TitleID
WHERE Q.Requirement = 'Jaguar Spain Sales'
AND PAP.AddressingTypeID = 1
AND T.TitleID IN (18, 356)

UPDATE PAP
SET PAP.GenderID = 1
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN Party.Titles T ON T.TitleID = PAP.TitleID
WHERE Q.Requirement = 'Jaguar Spain Sales'
AND PAP.AddressingTypeID = 2
AND T.TitleID IN (17, 84)

UPDATE PAP
SET PAP.GenderID = 2
FROM Party.PersonAddressingPatterns PAP
INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PAP.QuestionnaireRequirementID
INNER JOIN Party.Titles T ON T.TitleID = PAP.TitleID
WHERE Q.Requirement = 'Jaguar Spain Sales'
AND PAP.AddressingTypeID = 2
AND T.TitleID IN (18, 356)


