CREATE PROCEDURE [SelectionOutput].[uspGetAllPostalCombined]
@Brand [dbo].[OrganisationName], @Questionnaire [dbo].[Requirement], @Market [dbo].[Country], @Lang [dbo].[LanguageID]
AS
WITH Postal_CTE	([Password], ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, 
		Add8, Add9, CTRY, EmailAddress, Dealer, sno, ccode, modelcode, lang, 
		manuf, gender, qver, blank, etype, reminder, [week], test, SampleFlag, 
		SalesServiceFile, PartyID)
AS
(
	SELECT DISTINCT     
	PC.Password, 
	PC.ID, 
	PC.FullModel, 
	PC.Model, 
	PC.sType, 
	PC.CarReg, 
	PC.Title, 
	PC.Initial, 
	PC.Surname, 
	PC.Fullname, 
	PC.DearName, 
	PC.CoName, 
	PC.Add1, 
	PC.Add2, 
	PC.Add3, 
	PC.Add4, 
	PC.Add5, 
	PC.Add6, 
	PC.Add7, 
	PC.Add8, 
	PC.Add9, 
	PC.CTRY, 
	PC.EmailAddress, 
	PC.Dealer, 
	PC.sno, 
	PC.ccode, 
	PC.modelcode, 
	PC.lang, 
	PC.manuf, 
	PC.gender, 
	PC.qver, 
	PC.blank, 
	PC.etype, 
	PC.reminder, 
	PC.week, 
	PC.test, 
	PC.SampleFlag, 
	PC.SalesServiceFile, 
	PC.PartyID
	FROM SelectionOutput.PostalCombined PC
	INNER JOIN Requirement.SelectionCases SC ON PC.ID = SC.CaseID
	INNER JOIN Requirement.RequirementRollups RR ON SC.RequirementIDPartOf = RR.RequirementIDMadeUpOf
	INNER JOIN Requirement.Requirements R ON RR.RequirementIDPartOf = R.RequirementID
	INNER JOIN Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata SM ON R.RequirementID = SM.QuestionnaireRequirementID
	WHERE PC.DateOutput IS NULL 
	AND PC.Outputted		= 1
	AND SM.Brand			= @Brand
	AND PC.CTRY				= @Market
	AND SM.Questionnaire	= @Questionnaire
	AND (ISNULL(PC.BilingualFlag,'FALSE') = 'FALSE' OR PC.lang = @Lang)			
)

--BUG 14195 
SELECT *
FROM	Postal_CTE pc
ORDER BY row_number() OVER (PARTITION BY lang ORDER BY lang), lang


