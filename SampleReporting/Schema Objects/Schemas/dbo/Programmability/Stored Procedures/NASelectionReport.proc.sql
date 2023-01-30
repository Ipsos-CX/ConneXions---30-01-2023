CREATE PROCEDURE [dbo].[NASelectionReport]

	AS

	/*
	Purpose:	North American Selection Report
		
	Version		Date				Developer			Comment
	1.1			15/01/2020			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.2			19/04/2021			Chris Ledger		TASK 398 - Tidy formating
	*/

	INSERT INTO dbo.NA_SelectionReport (SelectionName, SelectionRequirementID, DateLastRun, Brand, Market, Questionnaire, Caseid, VIN, EventDate, DealerCode)
	SELECT R.Requirement AS SelectionName, 
		R.RequirementID AS SelectionRequirementID, 
		CONVERT(VARCHAR, SR.DateLastRun, 103) AS DateLastRun, 
		MD.Brand, 
		MD.Market, 
		MD.Questionnaire, 
		CD.CaseID, 
		CD.VIN, 
		CONVERT(VARCHAR, CD.EventDate, 103) AS EventDate, [DealerCode]
	FROM [$(SampleDB)].dbo.Markets M	
	--NORTH AMERICA I.E. USA & Canada
		INNER JOIN [$(SampleDB)].dbo.Regions RE	ON M.RegionID = RE.RegionID 
													AND RE.Region ='North America NSC'
		INNER JOIN [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata MD ON M.CountryID = MD.CountryID 
													AND MD.Questionnaire IN ('Sales','Service')
		INNER JOIN [$(SampleDB)].Requirement.RequirementRollups RR ON MD.QuestionnaireRequirementID = RR.RequirementIDPartOf
		INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements SR ON RR.RequirementIDMadeUpOf = SR.RequirementID
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON SR.RequirementID = CD.SelectionRequirementID
		INNER JOIN [$(SampleDB)].Requirement.Requirements R ON SR.RequirementID = R.RequirementID
	-- SELECTIONS THAT RAN TODAY
	WHERE DATEDIFF(DD, SR.DateLastRun, GETDATE()) = 0
