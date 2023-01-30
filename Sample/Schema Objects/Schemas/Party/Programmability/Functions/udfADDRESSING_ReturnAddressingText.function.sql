/*CREATE         FUNCTION [dbo].[udfADDRESSING_ReturnAddressingText]
(
	@PartyID INT, 
	@RequirementID SMALLINT, 
	@AddressingPatternTypeID TINYINT
)  
RETURNS NVARCHAR(500) 
AS  

/*
Description
-----------
Returns the addressing text required for a given Party, Addressing PatternType, and Requirement

Parameters
-----------
@PartyID

@RequirementID
	Questionnaire Requirement

@AddressingPatternTypeID
	i.e. Salutation / Addressee / Telephone salutation, etc.

Version		Date		Aurthor		Why
------------------------------------------------------------------------------------------------------
1.0		20/01/2004	Mark Davidson	Created
1.1		04/02/2004	Mark Davidson	Add Proper casing
1.2		05/02/2004	Mark Davidson	Remove first names containing just '.'
1.3		19/03/2004	Mark Davidson	Remove Proper casing
1.4		27/04/2004	Mark Davidson	Added code to accommodate new db structure
									facilitating addressing by gender / language
									with or without titles
1.5		26/05/2004	Mark Davidson	Added code to accommodate Organisation addressing patterns
									incorporating organisation name
1.6		02/06/2004	Mark Davidson	Added code to accommodate changes to vwADDRESSING_PersonAddressingPatterns
									This now unions title-specific and non-title-specific patterns
									so as to facilitate simpler defaulting to, for example, gender-based
									salutation when unknown title is encountered.
1.7		17/08/2011	Simon Peacock	Updated to handle translation from English to Portuguese for Brazil Sales

*/
BEGIN 

	DECLARE @Addressing NVARCHAR(500)
	DECLARE @Person BIT
	DECLARE @Organisation BIT
	
	DECLARE @AddressingPattern NVARCHAR(100)
	DECLARE @AddressingPatternID INT
	DECLARE @DefaultAddressingPattern NVARCHAR(100)
	DECLARE @AddressingGreetingDesc NVARCHAR(100)

	DECLARE @OrganisationName NVARCHAR(255)

	DECLARE @PreNominalTitleID SMALLINT
	DECLARE @PreNominalTitleDesc NVARCHAR(255)
	DECLARE @FirstName NVARCHAR(255)
	DECLARE @Initials NVARCHAR(30)
	DECLARE @MiddleName NVARCHAR(255)
	DECLARE @LastName NVARCHAR(255)
	DECLARE @SecondLastName NVARCHAR(255)
	DECLARE @PostNominalTitleDesc NVARCHAR(255)
	DECLARE @GenderID TINYINT

	DECLARE @LanguageID SMALLINT

--Set language for this party from PartyLanguages
	SELECT 
		@LanguageID = pl.LanguageID
	FROM
		dbo.PartyLanguages AS pl
	WHERE
		pl.PartyID = @PartyID
		AND pl.PreferredFlag = 1

/*
	Initialise local variables
	according to party type
*/
	SELECT 
		@Person = CASE WHEN p.PartyID IS NULL THEN 0 ELSE 1 END, 
		@Organisation = CASE WHEN org.PartyID IS NULL THEN 0 ELSE 1 END
	FROM
		dbo.Parties AS pty
		LEFT JOIN
			dbo.People AS p
			ON p.PartyID = pty.PartyID
			LEFT JOIN
				dbo.Organisations AS org
				ON org.PartyID = pty.PartyID
	WHERE
		pty.PartyID = @PartyID

/*
	If Party is neither organisation or person
	treat as organisations
*/
	IF @Person = 0 AND @Organisation = 0
		SET @Organisation = 1

--Get Addressing Greeting
	SELECT 
		@AddressingGreetingDesc = g.AddressingGreetingDesc
	FROM
		dbo.vwADDRESSING_Greetings AS g
	WHERE
		g.RequirementID = @RequirementID
/*
	EXEC dbo.uspADDRESSING_GetGreeting 
		@RequirementID, 
		@AddressingGreetingDesc OUTPUT

	SET @AddressingGreetingDesc = ISNULL(@AddressingGreetingDesc, N'')
*/
/*
*************************************************************************************
*************************************************************************************
	GET ADDRESSING PATTERN (PROCESS CONDITIONALLY DEPENDING ON PARTY TYPE)	
*************************************************************************************
*************************************************************************************

*************************************************************************************
	PERSON
*************************************************************************************
*/
	IF @Person = 1
		BEGIN
--Initialise variables
--Person details
			SELECT
				@PreNominalTitleID = p.PreNominalTitleID, 
				@PreNominalTitleDesc = p.PreNominalTitleDesc, 
				@FirstName = LTRIM(RTRIM(p.FirstName)), 
				@Initials = LTRIM(RTRIM(p.Initials)), 
				@LastName = LTRIM(RTRIM(p.LastName)), 
				@SecondLastName = LTRIM(RTRIM(p.SecondLastName)), 
				@PostNominalTitleDesc = p.PostNominalTitleDesc, 
				@GenderID = p.GenderID
			FROM
				dbo.vwGENERAL_People AS p
			WHERE
				p.PartyID = @PartyID

/*
	Replace first names that are just '.' with empty string
	5/2/2004 MD
*/
			SET @FirstName = ISNULL(NULLIF(@FirstName, '.'), N'')

--Addressing Pattern
			SELECT 
				@AddressingPatternTypeID = pap.AddressingPatternTypeID, 
				@RequirementID = pap.RequirementID, 
				@PreNominalTitleID = pap.PreNominalTitleID, 
				@AddressingPatternID = pap.AddressingPatternID
			FROM
				dbo.vwADDRESSING_PersonAddressingPatterns AS pap 
				JOIN dbo.vwGENERAL_Countries AS cnt
					ON pap.CountryID = cnt.CountryID
			WHERE
				pap.RequirementID = @RequirementID
				AND pap.AddressingPatternTypeID = @AddressingPatternTypeID
				AND pap.PreNominalTitleID = @PreNominalTitleID
				AND (pap.LanguageID = ISNULL(@LanguageID, cnt.DefaultLanguageID) OR pap.LanguageID IS NULL)
				AND (pap.GenderID = @GenderID OR pap.GenderID IS NULL)

--If no rows returned above, check for non-title-specific pattern
			IF @AddressingPatternID IS NULL
				SELECT TOP 1
					@AddressingPatternTypeID = pap.AddressingPatternTypeID, 
					@RequirementID = pap.RequirementID, 
					@PreNominalTitleID = pap.PreNominalTitleID, 
					@AddressingPatternID = pap.AddressingPatternID
				FROM
					dbo.vwADDRESSING_PersonAddressingPatterns AS pap 
					JOIN dbo.vwGENERAL_Countries AS cnt
						ON pap.CountryID = cnt.CountryID
				WHERE
					pap.RequirementID = @RequirementID
					AND pap.AddressingPatternTypeID = @AddressingPatternTypeID
					AND pap.PreNominalTitleID IS NULL
					AND 
					(
						pap.LanguageID = ISNULL(@LanguageID, cnt.DefaultLanguageID) OR pap.LanguageID IS NULL
					)
					AND 
					(
						pap.GenderID = @GenderID OR pap.GenderID IS NULL
					)							
				ORDER BY
					ISNULL(pap.LanguageID, 0) DESC, 
					ISNULL(pap.GenderID, 0) DESC
/*
					AND pap.PreNominalTitleID IS NULL
					AND (pap.LanguageID = ISNULL(@LanguageID, cnt.DefaultLanguageID) OR pap.LanguageID IS NULL)
					AND (pap.GenderID = @GenderID OR pap.GenderID IS NULL)
*/					
--If no rows returned above, use the default

			IF @AddressingPatternID IS NULL
				SELECT
					@AddressingPatternID = dap.AddressingPatternID
				FROM
					dbo.vwADDRESSING_DefaultAddressingPatterns AS dap
				WHERE
					dap.AddressingPatternTypeID = @AddressingPatternTypeID

/*
	Check to see if any required pattern elements lack
	corresponding details
*/
			DECLARE @MissingElements BIT
			SELECT 
				@MissingElements = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
			FROM 
				dbo.AddressingPatternElements AS ape
			WHERE 
				ape.AddressingPatternID = @AddressingPatternID
				AND ape.Required = 1
				AND 
					CASE 
						WHEN (NULLIF(@AddressingGreetingDesc, N'') IS NULL AND CHARINDEX('@AddressingGreetingDesc', ape.ElementDesc) > 0) 
						THEN 1
						WHEN (NULLIF(@PreNominalTitleDesc, N'') IS NULL AND CHARINDEX('@PreNom', ape.ElementDesc) > 0)
						THEN 1
						WHEN (NULLIF(@PostNominalTitleDesc, N'') IS NULL AND CHARINDEX('@PostNom', ape.ElementDesc) > 0)
						THEN 1
						WHEN (NULLIF(@FirstName, N'') IS NULL AND NULLIF(@Initials, N'') IS NULL AND CHARINDEX('@Initials', ape.ElementDesc) > 0 AND CHARINDEX('@FirstName', ape.ElementDesc)>0)
						THEN 1
						WHEN (NULLIF(@FirstName, N'') IS NULL AND CHARINDEX('@FirstName', ape.ElementDesc) > 0)
						THEN 1
						WHEN (NULLIF(@MiddleName, N'') IS NULL AND CHARINDEX('@MiddleName', ape.ElementDesc) > 0)
						THEN 1
						WHEN (NULLIF(@LastName, N'') IS NULL AND CHARINDEX('@LastName', ape.ElementDesc) > 0)
						THEN 1
						WHEN (NULLIF(@SecondLastName, N'') IS NULL AND CHARINDEX('@SecondLastName', ape.ElementDesc) > 0)
						THEN 1
						ELSE 0
					END > 0

--If missing elements exist, use organisation
		IF @MissingElements = 1
			BEGIN
				SET @Organisation = 1
				SET @Person = 0
			END

	END
/*
*************************************************************************************
	ORGANISATION
*************************************************************************************
*/

	IF @Organisation = 1
		BEGIN	
--Get OrganisationName
			SELECT
				@OrganisationName = o.OrganisationName
			FROM
				dbo.Organisations AS o
			WHERE
				o.PartyID = @PartyID

--Reset AddressingPatternID
			SET @AddressingPatternID = NULL

--Addressing Pattern
			SELECT
				@AddressingPatternID = oap.AddressingPatternID
			FROM
				dbo.vwADDRESSING_OrganisationAddressingPatterns AS oap
				JOIN dbo.vwGENERAL_Countries AS cnt
					ON oap.CountryID = cnt.CountryID
			WHERE
				oap.RequirementID = @RequirementID
				AND oap.AddressingPatternTypeID = @AddressingPatternTypeID
				AND (oap.LanguageID = ISNULL(@LanguageID, cnt.DefaultLanguageID) OR oap.LanguageID IS NULL)
/*
			EXEC uspADDRESSING_GetOrganisationAddressingPattern
				@AddressingPatternTypeID = @AddressingPatternTypeID, 
				@RequirementID = @RequirementID, 
				@AddressingPattern = @AddressingPattern OUTPUT 
*/
		END

/*
*************************************************************************************
*************************************************************************************
	CONSTRUCT FINAL ADDRESSING STRING (PROCESS CONDITIONALLY DEPENDING ON PARTY TYPE)	
*************************************************************************************
*************************************************************************************
*/

--Get Addressing Pattern (If NULL, return an empty string)
	SET @AddressingPattern = ISNULL(dbo.udfADDRESSING_ConstructAddressingPattern(@AddressingPatternID), N'')

--Initialise return variable
	SET @Addressing = @AddressingPattern


--Construct string
	SET @Addressing = REPLACE(@Addressing, '@AddressingGreeting', ISNULL(@AddressingGreetingDesc, N''))
	SET @Addressing = REPLACE(@Addressing, '@PreNomENGToBRA', CASE @PreNominalTitleDesc
																WHEN N'Mr' THEN N'Sr'
																WHEN N'Mrs' THEN N'Sra'
																WHEN N'Ms' THEN N'Sra'
																ELSE N''
															END)
	SET @Addressing = REPLACE(@Addressing, '@PreNomHerrToHerrn', REPLACE(ISNULL(@PreNominalTitleDesc, N''), N'Herr', N'Herrn'))
	SET @Addressing = REPLACE(@Addressing, '@PreNom', ISNULL(@PreNominalTitleDesc, N''))
	SET @Addressing = REPLACE(@Addressing, ', @PostNom', ISNULL(N', ' + NULLIF(@PostNominalTitleDesc, N''), N''))
	SET @Addressing = REPLACE(@Addressing, '@PostNom', ISNULL(@PostNominalTitleDesc, N''))
	SET @Addressing = REPLACE(@Addressing, '@FirstName/@Initials', COALESCE(NULLIF(@FirstName, N''), NULLIF(@Initials, N''), N''))
	SET @Addressing = REPLACE(@Addressing, '@Initials/@FirstName', COALESCE(NULLIF(@Initials, N''), NULLIF(@FirstName, N''), N''))
	SET @Addressing = REPLACE(@Addressing, '@FirstName', ISNULL(@FirstName, N''))
	SET @Addressing = REPLACE(@Addressing, '@LastName', ISNULL(@LastName, N''))
	SET @Addressing = REPLACE(@Addressing, '@SecondLastName', ISNULL(@SecondLastName, N''))
	SET @Addressing = REPLACE(@Addressing, '@OrganisationName', ISNULL(@OrganisationName, N''))
	SET @Addressing = REPLACE(LTRIM(RTRIM(@Addressing)), N'  ', N' ')
	SET @Addressing = REPLACE(@Addressing, N' ,', N',')


--Return value
	RETURN(@Addressing)


END*/



