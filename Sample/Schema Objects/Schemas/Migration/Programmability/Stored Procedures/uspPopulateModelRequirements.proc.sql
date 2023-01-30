CREATE PROCEDURE [Migration].[uspPopulateModelRequirements]

AS

SELECT DISTINCT M.RequirementID, VM.ModelID
INTO #Models
FROM Requirement.Requirements M
INNER JOIN QuestionnaireModelDerivatives QMD ON QMD.RequirementIDMadeUpOf = M.RequirementID
INNER JOIN Vehicle.Models VM ON VM.ModelDescription = QMD.ShortModelDesc
WHERE M.RequirementTypeID = 4

;WITH VehicleModels AS (
	SELECT DISTINCT M.RequirementID,
		CASE
			WHEN QMD.ShortModelDesc LIKE 'Discovery%' THEN 'Discovery'
			WHEN QMD.ShortModelDesc LIKE 'Free%' THEN 'Freelander'
			WHEN QMD.ShortModelDesc LIKE '%XK%' THEN 'XK'
			WHEN QMD.ShortModelDesc LIKE '%X-TYPE%' THEN 'X-TYPE'
			WHEN QMD.ShortModelDesc LIKE '%XTYPE%' THEN 'X-TYPE'
			WHEN QMD.ShortModelDesc LIKE 'Range Rover Sport%' THEN 'Range Rover Sport'
			WHEN QMD.ShortModelDesc LIKE 'Range Rover%' THEN 'Range Rover'
			WHEN QMD.ShortModelDesc LIKE 'S-TYPE%' THEN 'S-TYPE'
			WHEN QMD.ShortModelDesc LIKE 'XF%' THEN 'XF'
			WHEN QMD.ShortModelDesc LIKE 'XJ%' THEN 'XJ'
		END AS Model
	FROM Requirement.Requirements M
	INNER JOIN QuestionnaireModelDerivatives QMD ON QMD.RequirementIDMadeUpOf = M.RequirementID
	WHERE M.RequirementTypeID = 4
	AND M.RequirementID NOT IN (SELECT RequirementID FROM #Models)
)
INSERT INTO #Models
SELECT DISTINCT VM.RequirementID, M.ModelID
FROM VehicleModels VM
INNER JOIN Vehicle.Models M ON M.ModelDescription = VM.Model

;WITH VehicleModels AS (
	SELECT DISTINCT RequirementID,
			CASE
				WHEN Requirement LIKE 'Discovery%' THEN 'Discovery'
				WHEN Requirement LIKE 'Free%' THEN 'Freelander'
				WHEN Requirement LIKE '%XK%' THEN 'XK'
				WHEN Requirement LIKE '%X-TYPE%' THEN 'X-TYPE'
				WHEN Requirement LIKE '%XTYPE%' THEN 'X-TYPE'
				WHEN Requirement LIKE 'Range Rover Sport%' THEN 'Range Rover Sport'
				WHEN Requirement LIKE 'Range Rover%' THEN 'Range Rover'
				WHEN Requirement LIKE 'S-TYPE%' THEN 'S-TYPE'
				WHEN Requirement LIKE 'XF%' THEN 'XF'
				WHEN Requirement LIKE '%XJ%' THEN 'XJ'
			END AS Model
	FROM Requirement.Requirements
	WHERE RequirementTypeID = 4
	AND RequirementID NOT IN (SELECT RequirementID FROM #Models)
)
INSERT INTO #Models
SELECT DISTINCT VM.RequirementID, M.ModelID
FROM VehicleModels VM
INNER JOIN Vehicle.Models M ON M.ModelDescription = VM.Model

INSERT INTO #Models (RequirementID, ModelID)
VALUES (18645, 10)

-- WE END UP WITH A FEW DUPLICATES DUE TO SOME DODGY DATA
DELETE FROM #Models WHERE RequirementID = 6853 AND ModelID = 9
DELETE FROM #Models WHERE RequirementID = 8972 AND ModelID = 9
DELETE FROM #Models WHERE RequirementID = 10677 AND ModelID = 9
DELETE FROM #Models WHERE RequirementID = 13169 AND ModelID = 9
DELETE FROM #Models WHERE RequirementID = 1465 AND ModelID = 9
DELETE FROM #Models WHERE RequirementID = 18287 AND ModelID = 10
DELETE FROM #Models WHERE RequirementID = 6853 AND ModelID = 10
DELETE FROM #Models WHERE RequirementID = 5080 AND ModelID = 10
DELETE FROM #Models WHERE RequirementID = 1466 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 11206 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 18290 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 14231 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 23638 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 13170 AND ModelID = 11
DELETE FROM #Models WHERE RequirementID = 5725 AND ModelID = 13
DELETE FROM #Models WHERE RequirementID = 10679 AND ModelID = 13
DELETE FROM #Models WHERE RequirementID = 5726 AND ModelID = 15
DELETE FROM #Models WHERE RequirementID = 10678 AND ModelID = 15
DELETE FROM #Models WHERE RequirementID = 81 AND ModelID = 4


INSERT INTO Requirement.ModelRequirements (RequirementID, ModelID)
SELECT DISTINCT RequirementID, ModelID
FROM #Models
ORDER BY RequirementID

DROP TABLE #Models


