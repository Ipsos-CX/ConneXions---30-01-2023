CREATE   PROCEDURE [dbo].[uspGET_QuestionnaireRequirementInformation]
(
	@RequirementID INT
)
AS
/*
Description
-----------
Creates summary report collating all relevant information on a given requirement.
This helps when setting up new requirements or diagnosing issues.

Parameters
-----------

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			13/03/2012	Attila Kubanda	Created
1.1			20/01/2020	Chris Ledger	Bug 15372 - Fix database references
Eddie Testv1
							

*/
--Disable Counts
	SET NOCOUNT ON

--Rollback on error
	SET XACT_ABORT ON	

--Validate parameters
	IF NOT EXISTS
	(
		SELECT *
		FROM 
			[Requirement].QuestionnaireRequirements AS QR
		WHERE
			QR.RequirementID = @RequirementID
	)
		BEGIN
			--RAISERROR 50001 'Invalid Requirement ID'
			RETURN
		END
---------------------------------------------------------------------------------------------------
--Declare local variables
---------------------------------------------------------------------------------------------------
	DECLARE @QuestionnaireName NVARCHAR(255)
	DECLARE @Countries NVARCHAR(500)
	DECLARE @EventType NVARCHAR(500)
	DECLARE @CR NVARCHAR(1)
	DECLARE @Tab NVARCHAR(1)
	DECLARE @Divider NVARCHAR(255)
	DECLARE @FirstDivider NVARCHAR(255)
	DECLARE @TopDivider NVARCHAR(255)
	DECLARE @BottomDivider NVARCHAR(255)
	DECLARE @WarningStart NVARCHAR(25)
	DECLARE @WarningEnd NVARCHAR(25)
	DECLARE @QuestionnaireRequirement NVARCHAR(1000)
	DECLARE @Programme NVARCHAR(255)
	DECLARE @Processing NVARCHAR(255)
	DECLARE @Models NVARCHAR(4000)
	DECLARE @QSDetails NVARCHAR(1000)
	DECLARE @OutputFileMetadata NVARCHAR(4000)
	DECLARE @TimeDriven NVARCHAR(255)
	DECLARE @PersonAddressing NVARCHAR(4000)
	DECLARE @OrganisationAddressing NVARCHAR(4000)
	DECLARE @Associations NVARCHAR(4000)
	DECLARE @FromAssociations NVARCHAR(4000)
	DECLARE @ToAssociations NVARCHAR(4000)
---------------------------------------------------------------------------------------------------
--Initialise local variables
---------------------------------------------------------------------------------------------------
	SET @CR = NCHAR(13)
	SET @Tab = NCHAR(9)
	SET @Divider = REPLICATE('*', 70)
	SET @FirstDivider = @Divider
	SET @TopDivider = @CR + @CR + @Divider
	SET @BottomDivider = @Divider
	SELECT 
		@QuestionnaireName = R.[Requirement] 
	FROM 
		[Requirement].Requirements AS R 
	WHERE 
		R.RequirementID = @RequirementID

	SET @WarningStart = N'!!!WARNING - '
	SET @WarningEnd = N'!!!'
---------------------------------------------------------------------------------------------------
--Questionnaire Requirement
---------------------------------------------------------------------------------------------------
	PRINT @FirstDivider
	PRINT UPPER('Questionnaire Requirement')
	PRINT @BottomDivider
	SELECT
		@QuestionnaireRequirement = 
		'Manufacturer = ' + COALESCE(O.OrganisationName, '[NULL]') + COALESCE(' (' + CAST(o.PartyID AS VARCHAR(20)) + ')', '')
		+ @CR
		+ 'Start Days = ' + CAST(QR.StartDays AS VARCHAR(25))
		+ @CR
		+ 'End Days = ' + CAST(QR.EndDays AS VARCHAR(25))
		+ @CR
		+ 'QuestionnaireIncompatibilityDays = ' + COALESCE(CAST(QR.QuestionnaireIncompatibilityDays AS VARCHAR(25)), '[NULL]') 
		+ @CR
	FROM
		[Requirement].QuestionnaireRequirements AS QR
		LEFT JOIN [Party].Organisations AS O
			ON O.PartyID = QR.ManufacturerPartyID
	WHERE
		QR.RequirementID = @RequirementID

	PRINT @QuestionnaireRequirement
---------------------------------------------------------------------------------------------------
--Countries
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT UPPER('Associated Countries')
	PRINT @BottomDivider

	IF NOT EXISTS 
		(
			SELECT * 
			FROM 
				[Requirement].QuestionnaireRequirements AS QRC 
			WHERE 
				QRC.RequirementID = @RequirementID
				AND 
				QRC.CountryID IS NOT NULL
		)
			
		SET @Countries = @WarningStart + 'No Countries are association with this Questionnaire' + @WarningEnd
			
	ELSE
		SELECT 
			@Countries = COALESCE(@Countries + N', ', N'') + CNT.Country + ' (' + LTRIM(RTRIM(STR(CNT.CountryID))) + ')'
		FROM 
			[Requirement].QuestionnaireRequirements AS QRC
			LEFT JOIN [ContactMechanism].Countries AS CNT ON QRC.CountryID = CNT.CountryID
		WHERE
			QRC.RequirementID = @RequirementID
		

	PRINT @Countries
---------------------------------------------------------------------------------------------------
--Event Type, Ownership Cycle, etc.
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT UPPER('Event Type, etc.')
	PRINT @BottomDivider
	SELECT
		@EventType = 
		'Event Type = ' + COALESCE(ET.EventType, '[NULL]') 
		+ @CR
		--+ 'Role Type = '  + COALESCE(vrt.VehicleRoleTypeDesc, '[NULL]') 
		--+ @CR
		+ 'Ownership Cycle = ' + COALESCE(CAST(QRC.OwnershipCycle AS VARCHAR(3)), '[NULL]')

	FROM
		[Requirement].QuestionnaireRequirements AS QRC
		LEFT JOIN [Event].EventTypeCategories EC ON EC.EventCategoryID = QRC.EventCategoryID
		LEFT JOIN [Event].EventTypes ET ON ET.EventTypeID = EC.EventTypeID

	WHERE
		QRC.RequirementID = @RequirementID

	PRINT @EventType
---------------------------------------------------------------------------------------------------
--Programme
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT UPPER('Programme')
	PRINT @BottomDivider
	SELECT
		@Programme = PROG.[Requirement] + ' (' + CAST(PROG.RequirementID AS VARCHAR(20)) + ')'
	FROM
		[Requirement].RequirementRollups AS RR
		INNER JOIN [Requirement].Requirements AS PROG
			ON RR.RequirementIDPartOf = PROG.RequirementID
				AND PROG.RequirementTypeID = 1 --Programme
	WHERE
		RR.RequirementIDMadeUpOf = @RequirementID
	PRINT @Programme
---------------------------------------------------------------------------------------------------
--Questionnaire - Selection Details
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT 'Questionnaire - Selection Details'
	PRINT @BottomDivider
	SELECT DISTINCT
		@QSDetails = 
			COALESCE(@QSDetails + @CR, N'') 
			+ @CR
			+ 'SelectionName = ' + COALESCE(BMQSM.SelectionName, '[NULL]') 
			+ @CR
			+ 'Enabled Flag = ' + COALESCE(CAST(BMQSM.[Enabled] AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'CreateSelection Flag = ' + COALESCE(CAST(BMQSM.CreateSelection AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'StreetRequired Flag = ' + COALESCE(CAST(BMQM.StreetRequired AS VARCHAR(5)), '[NULL]')
			+ @CR
			+ 'PostCodeRequired Flag = ' + COALESCE(CAST(BMQM.PostCodeRequired AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'EmailRequired Flag = ' + COALESCE(CAST(BMQM.EmailRequired AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'TelephoneRequired Flag = ' + COALESCE(CAST(BMQM.TelephoneRequired AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'StreetOrEmailRequired Flag = ' + COALESCE(CAST(BMQM.StreetOrEmailRequired AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'TelephoneOrEmailRequired Flag = ' + COALESCE(CAST(BMQM.TelephoneOrEmailRequired AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ @CR
			+ 'SelectSales Flag = ' + COALESCE(CAST(BMQM.SelectSales AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'SelectService Flag = ' + COALESCE(CAST(BMQM.SelectService AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'SelectWarranty Flag = ' + COALESCE(CAST(BMQM.SelectWarranty AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'SelectRoadSide Flag = ' + COALESCE(CAST(BMQM.SelectRoadSide AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ @CR
			+ 'SelectionOutputActive Flag = ' + COALESCE(CAST(BMQM.SelectionOutputActive AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'IncludeEmailOutputInAllFile Flag = ' + COALESCE(CAST(BMQM.IncludeEmailOutputInAllFile AS VARCHAR(5)), '[NULL]') 
			+ @CR
			+ 'IncludePostalOutputInAllFile Flag = ' + COALESCE(CAST(BMQM.IncludePostalOutputInAllFile AS VARCHAR(5)), '[NULL]')	+ @CR
			+ 'IncludeCATIOutputInAllFile Flag = ' + COALESCE(CAST(BMQM.IncludeCATIOutputInAllFile AS VARCHAR(5)), '[NULL]')	+ @CR
			+ 'IncludeInOnlineDealerList Flag = ' + COALESCE(CAST(BMQM.IncludeInOnlineDealerList AS VARCHAR(5)), '[NULL]')	+ @CR
			+ 'IncludeInOWAP Flag = ' + COALESCE(CAST(BMQM.IncludeInOWAP AS VARCHAR(5)), '[NULL]') 		
			+ @CR
			+ 'ContactMethod Flag = ' + COALESCE(CT.ContactMethodologyType, '[NULL]') 
						
	FROM
		[Requirement].QuestionnaireRequirements AS QR
		INNER JOIN [dbo].BrandMarketQuestionnaireSampleMetadata AS BMQSM ON QR.RequirementID = BMQSM.QuestionnaireRequirementID
		INNER JOIN [dbo].BrandMarketQuestionnaireMetadata AS BMQM ON BMQSM.BMQID = BMQM.BMQID
		INNER JOIN [SelectionOutput].ContactMethodologyTypes CT ON CT.ContactMethodologyTypeID = BMQM.ContactMethodologyTypeID
	WHERE
		QR.RequirementID = @RequirementID
	PRINT @QSDetails

---------------------------------------------------------------------------------------------------
--Questionnaire Associations
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT UPPER('Questionnaire Associations')
	PRINT @BottomDivider

	IF EXISTS
		(
			SELECT *
			FROM 
				[Requirement].QuestionnaireAssociations AS QA
			WHERE 
				 QA.RequirementIDTo = @RequirementID
		)
		BEGIN
--From Associations
			PRINT 'The following questionnaires are associated to ' + @QuestionnaireName + ':'
			SELECT 
				
				@FromAssociations = COALESCE(@FromAssociations + @CR, '') 
				+ @Tab
				+ 'Questionnaire = ' + R.[Requirement] + ' (' + CAST(R.RequirementID AS VARCHAR(20)) + ')'
				+ @CR 
				+ @Tab
				+ 'Date From = ' + CAST(QA.FromDate AS VARCHAR(106)) 
				+ @CR 
				+ @Tab
				+ 	CASE 
						WHEN QI.RequirementIDFrom IS NOT NULL 
						THEN 
							'Type = Incompatible' 
							--+ @CR 
							--+ @Tab
							--+ 'Reason = ' + COALESCE(QI.Reason, '[NULL]')
							+ @CR
							+ @Tab
							+ 'Date To = ' + COALESCE(CAST(QI.ThroughDate AS VARCHAR(106)), '[NULL]')
							+ @CR
						ELSE ''
					END


			FROM
				[Requirement].QuestionnaireAssociations AS QA
				INNER JOIN [Requirement].Requirements AS R
					ON R.RequirementID = QA.RequirementIDFrom
					LEFT JOIN [Requirement].QuestionnaireIncompatibilities AS QI
						ON QI.RequirementIDFrom = QA.RequirementIDFrom
							AND QI.RequirementIDTo = QA.RequirementIDTo
							AND QI.FromDate = QA.FromDate
			WHERE
				QA.RequirementIDTo = @RequirementID

			PRINT @FromAssociations
		END

	IF EXISTS
		(
			SELECT *
			FROM 
				[Requirement].QuestionnaireAssociations AS QA
			WHERE 
				 QA.RequirementIDFrom = @RequirementID
		)
		BEGIN
			PRINT @CR
--To Associations
			PRINT @QuestionnaireName + ' is associated to the following questionnaires:'
			SELECT 
				
				@ToAssociations = COALESCE(@ToAssociations + @CR, '') 
				+ @Tab
				+ 'Questionnaire = ' + R.[Requirement] + ' (' + CAST(R.RequirementID AS VARCHAR(20)) + ')'
				+ @CR
				+ @Tab
				+ 'Date From = ' + CAST(QA.FromDate AS VARCHAR(106)) 
				+ @CR
				+ @Tab
				+ 	CASE 
						WHEN QI.RequirementIDTo IS NOT NULL 
						THEN 
							'Type = Incompatible' 
							--+ @CR 
							--+ @Tab
							--+ 'Reason = ' + COALESCE(qi.Reason, '[NULL]')
							+ @CR
							+ @Tab
							+ 'Date To = ' + COALESCE(CAST(QI.ThroughDate AS VARCHAR(106)), '[NULL]')
							+ @CR
						ELSE ''
					END


			FROM
				[Requirement].QuestionnaireAssociations AS QA
				INNER JOIN [Requirement].Requirements AS R
					ON R.RequirementID = QA.RequirementIDTo
					LEFT JOIN [Requirement].QuestionnaireIncompatibilities AS QI
						ON QI.RequirementIDFrom = QA.RequirementIDFrom
							AND QI.RequirementIDTo = QA.RequirementIDTo
							AND QI.FromDate = QA.FromDate
			WHERE
				QA.RequirementIDFrom = @RequirementID
			PRINT @ToAssociations
		END
	ELSE
		PRINT @WarningStart + 'This questionnaire is not involved in any associations' + @WarningEnd

---------------------------------------------------------------------------------------------------
--Addressing patterns
---------------------------------------------------------------------------------------------------
	PRINT @TopDivider
	PRINT UPPER('Addressing Patterns')
	PRINT @BottomDivider
	IF NOT EXISTS (SELECT * FROM [Party].PersonAddressingPatterns AS RAP WHERE RAP.QuestionnaireRequirementID = @RequirementID) 
		BEGIN
			PRINT @WarningStart + 'No addressing patterns have been set up for this questionnaire' + @WarningEnd
		END
	ELSE
		BEGIN
----People
	
			PRINT 'PEOPLE'
			SELECT
				@PersonAddressing = COALESCE(@PersonAddressing + @CR, '') 
				+ 'Type = ' + AT.AddressingType
				+ @CR
				+ 'Pattern = ' + PAP.Pattern
				+ @CR
				+ 	CASE 
						WHEN PAP.TitleID IS NOT NULL
						THEN
							'Title = ' + T.Title
							+ @CR
						ELSE ''
					END
				+	CASE
						WHEN PAP.LanguageID IS NOT NULL
						THEN
							'Language = ' + L.[Language]
							+ @CR
						ELSE ''
					END
				+	CASE
						WHEN PAP.GenderID IS NOT NULL
						THEN
							'Gender = ' + G.Gender
							+ @CR 
						ELSE ''
					END
				+ @CR
			FROM
				[Party].PersonAddressingPatterns AS PAP
				LEFT JOIN [Party].Genders AS G ON G.GenderID = PAP.GenderID
				LEFT JOIN [dbo].Languages AS l	ON l.LanguageID = PAP.LanguageID
				LEFT JOIN [Party].AddressingTypes AT ON AT.AddressingTypeID = PAP.AddressingTypeID
				LEFT JOIN [Party].Titles T on T.Titleid = PAP.TitleID
				

			WHERE
				PAP.QuestionnaireRequirementID = @RequirementID
			ORDER BY
				PAP.Pattern
				
			PRINT @PersonAddressing

----Organisation
			PRINT 'ORGANISATIONS'
			SELECT
				@OrganisationAddressing = COALESCE(@OrganisationAddressing + @CR, '') 
				+ 'Type = ' + AT.AddressingType
				+ @CR
				+ 'Pattern = ' + OAP.Pattern
				+ @CR
				+	CASE
						WHEN OAP.LanguageID IS NOT NULL
						THEN
							'Language = ' + L.[Language]
							+ @CR
						ELSE ''
					END
				+ @CR
			FROM
				[Party].OrganisationAddressingPatterns AS OAP
				LEFT JOIN [dbo].Languages AS l	ON l.LanguageID = OAP.LanguageID
				LEFT JOIN [Party].AddressingTypes AT ON AT.AddressingTypeID = OAP.AddressingTypeID
			WHERE
				OAP.QuestionnaireRequirementID = @RequirementID
			ORDER BY
				OAP.Pattern
			PRINT @OrganisationAddressing
		END