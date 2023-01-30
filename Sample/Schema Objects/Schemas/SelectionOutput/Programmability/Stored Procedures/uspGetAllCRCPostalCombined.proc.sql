CREATE PROCEDURE [SelectionOutput].[uspGetAllCRCPostalCombined]
	@Brand [dbo].[OrganisationName], @Questionnaire [dbo].[Requirement], @Market [dbo].[Country], @Lang [dbo].[LanguageID]
	
	AS
	/*
	Description:	Gets all CRC postal records for combined output. 
	------------	Called by: Selection Output - Postal.dtsx (Postal CRC - Data Flow Task)

	Version		Created			Author			History		
	-------		-------			------			-------			
	1.0			25-02-2018		Eddie Thomas	Original version 

	*/
	
	WITH Postal_CTE	(Password, ID, EventDate, fullModel, Model, SType, Carreg, Title,
					Initial, Surname, fullname, dearname, CoName, add1, add2, add3,
					add4, add5, add6, add7, add8, add9, CTRY, EmailAddress,
					Dealer, sno, ccode, modelcode, lang, manuf, gender, qver,
					surveyscale, etype, reminder, week, test, sampleflag, CRCsurveyfile,
					ITYPE, Owner, GfKPartyID)
	AS
	(
		SELECT DISTINCT 
		PC.Password,
		PC.ID,
		PC.EventDate, 
		PC.fullModel,
		PC.Model,
		PC.SType,
		PC.Carreg,
		PC.Title,
		PC.Initial,
		PC.Surname,
		PC.fullname,
		PC.dearname,
		PC.CoName,
		PC.add1,
		PC.add2,
		PC.add3,
		PC.add4,
		PC.add5,
		PC.add6,
		PC.add7,
		PC.add8,
		PC.add9,
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
		pC.blank AS surveyscale,
		PC.etype,
		PC.reminder,
		PC.week,
		PC.test,
		PC.sampleflag,
		PC.SalesServiceFile AS CRCsurveyfile,
		'' AS ITYPE,
		[Owner],
		PC.PartyID AS GfKPartyID

		FROM SelectionOutput.PostalCombined								PC
		INNER JOIN Requirement.SelectionCases							SC	ON PC.ID					= SC.CaseID
		INNER JOIN Requirement.RequirementRollups						RR	ON SC.RequirementIDPartOf	= RR.RequirementIDMadeUpOf
		INNER JOIN Requirement.Requirements								R	ON RR.RequirementIDPartOf	= R.RequirementID
		INNER JOIN Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata	SM	ON R.RequirementID			= SM.QuestionnaireRequirementID
		WHERE	(PC.DateOutput IS NULL) 
				AND (PC.Outputted		= 1)
				AND (SM.Brand			= @Brand)
				AND (PC.CTRY			= @Market)
				AND (SM.Questionnaire	= @Questionnaire)
				AND (ISNULL(PC.BilingualFlag,'FALSE') = 'FALSE' OR PC.lang = @Lang)

	)

	--BUG 14195 
	SELECT *
	FROM	Postal_CTE pc
	ORDER BY row_number() OVER (PARTITION BY lang ORDER BY ID), lang
