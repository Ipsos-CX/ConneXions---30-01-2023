CREATE PROCEDURE [Migration].[uspPopulateQuestionnaireModelRequirements]

AS

-- POPULATE QuestionnaireModelRequirements



DELETE FROM Requirement.QuestionnaireModelRequirements

; WITH LatestSelections
AS (
	-- GET THE LATEST SELECTION FOR EACH QUESTIONNAIRE
	SELECT Q.RequirementID AS QuestionnaireRequirementID, MAX(SR.RequirementID) AS SelectionRequirementID
	FROM Requirement.Requirements P
	INNER JOIN Requirement.RequirementRollups PQ ON PQ.RequirementIDPartOf = P.RequirementID
	INNER JOIN Requirement.Requirements Q ON Q.RequirementID = PQ.RequirementIDMadeUpOf
	INNER JOIN Requirement.RequirementRollups QS ON QS.RequirementIDPartOf = PQ.RequirementIDMadeUpOf
	INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = QS.RequirementIDMadeUpOf
	WHERE P.Requirement = 'JLR 2004'
	AND SR.DateOutputAuthorised IS NOT NULL
	GROUP BY Q.RequirementID
)
INSERT INTO Requirement.QuestionnaireModelRequirements (RequirementIDPartOf, RequirementIDMadeUpOf)
SELECT DISTINCT LS.QuestionnaireRequirementID, M.RequirementID AS ModelRequirementID
FROM LatestSelections LS
INNER JOIN Requirement.RequirementRollups SM ON SM.RequirementIDPartOf = LS.SelectionRequirementID
INNER JOIN Requirement.Requirements M ON M.RequirementID = SM.RequirementIDMadeUpOf
ORDER BY QuestionnaireRequirementID


-- Add in Roadside
insert into Requirement.QuestionnaireModelRequirements (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)
values 
-- Jaguar
(80, 31822, GETDATE()),
(81, 31822, GETDATE()),
(110, 31822, GETDATE()),
(15259, 31822, GETDATE()),
(15260, 31822, GETDATE()),
-- Land Rover
(85, 31754, GETDATE()),
(86, 31754, GETDATE()),
(87, 31754, GETDATE()),
(5725, 31754, GETDATE()),
(5726, 31754, GETDATE()),
--(6853, 31754, GETDATE()), -- we don't use the Discovery 3 model requirement
(11206, 31754, GETDATE()),
(30284, 31754, GETDATE())



-- POPULATE SelectionAllocations

INSERT INTO Requirement.SelectionAllocations (RequirementIDMadeUpOf, RequirementIDPartOf)
SELECT DISTINCT SM.RequirementIDMadeUpOf, SM.RequirementIDPartOf
FROM Requirement.RequirementRollups SM
INNER JOIN Requirement.SelectionRequirements SR ON SR.RequirementID = SM.RequirementIDPartOf
INNER JOIN Requirement.ModelRequirements MR ON MR.RequirementID = SM.RequirementIDMadeUpOf

