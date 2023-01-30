CREATE PROCEDURE [Migration].[uspSetQuestionnaireRequirementsMetadata]

AS

-- set the OwnershipCycle
UPDATE QR
SET QR.OwnershipCycle = AQ.OwnershipCycle
FROM Requirement.QuestionnaireRequirements QR
INNER JOIN dbo.AutomotiveQuestionnaires AQ ON AQ.RequirementID = QR.RequirementID

-- set the EventCategoryID
update qr
set qr.EventCategoryID = 1
from Requirement.Requirements q
inner join Requirement.QuestionnaireRequirements qr on q.RequirementID = qr.RequirementID
where q.Requirement like 'Jaguar%sales'

update qr
set qr.EventCategoryID = 1
from Requirement.Requirements q
inner join Requirement.QuestionnaireRequirements qr on q.RequirementID = qr.RequirementID
where q.Requirement like 'Land Rover%sales'

update qr
set qr.EventCategoryID = 2
from Requirement.Requirements q
inner join Requirement.QuestionnaireRequirements qr on q.RequirementID = qr.RequirementID
where q.Requirement like 'Jaguar%Service'

update qr
set qr.EventCategoryID = 2
from Requirement.Requirements q
inner join Requirement.QuestionnaireRequirements qr on q.RequirementID = qr.RequirementID
where q.Requirement like 'Land Rover%Service'



-- set the QuestionnaireVersion
UPDATE QR
SET QR.QuestionnaireVersion = CAST(PFA32.[Description] AS INT)
FROM dbo.Products P 
INNER JOIN dbo.ProductRequirements PR ON PR.ProductID = P.ProductID
INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = PR.RequirementID
INNER JOIN dbo.ProductCategoryClassifications PGC ON PGC.ProductID = P.ProductID
INNER JOIN dbo.vwProductFeatureApplicabilities PFA32 ON P.ProductID = PFA32.ProductID AND PFA32.ProductFeatureCategoryID = 32
WHERE PGC.ProductCategoryID = 23

-- update Roadside
UPDATE QR
SET QR.EventCategoryID = (SELECT EventCategoryID FROM Event.EventCategories WHERE EventCategory = 'Roadside'),
QR.QuestionnaireVersion = 1
FROM Requirement.Requirements q
INNER JOIN Requirement.QuestionnaireRequirements QR ON QR.RequirementID = Q.RequirementID
WHERE Q.Requirement LIKE '%roadside%'