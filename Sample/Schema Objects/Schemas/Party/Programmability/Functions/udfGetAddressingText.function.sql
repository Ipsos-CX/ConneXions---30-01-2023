CREATE FUNCTION [Party].[udfGetAddressingText]
(@PartyID [dbo].[PartyID], @QuestionnaireRequirementID [dbo].[RequirementID], @CountryID [dbo].[CountryID], @LanguageID [dbo].[LanguageID], @AddressingTypeID [dbo].[AddressingTypeID])
RETURNS [dbo].[AddressingText]
AS
BEGIN

	-- DECLARE THE RETURN VARIABLE
	DECLARE @AddressingText dbo.AddressingText
	DECLARE @AddressingPatternID INT

	--TASK 538
	DECLARE @OverrideAddressingText INT

	-- FIND OUT IF THE PartyID SUPPLIED IS FOR A PERSON OR ORGANISATION
	DECLARE @Person BIT
	DECLARE @Organisation BIT
	
	SET @Person = 0
	SET @Organisation = 0
	
	SELECT @Person = 1
	FROM Party.People
	WHERE PartyID = @PartyID
	
	IF @Person = 0 AND @Organisation = 0
	BEGIN
		SET @Organisation = 1
	END
	

	DECLARE @OrganisationName dbo.OrganisationName

	DECLARE @TitleID dbo.Title
	DECLARE @Title dbo.Title
	DECLARE @FirstName dbo.NameDetail
	DECLARE @Initials dbo.NameDetail
	DECLARE @MiddleName dbo.NameDetail
	DECLARE @LastName dbo.NameDetail
	DECLARE @SecondLastName dbo.NameDetail
	DECLARE @GenderID dbo.GenderID
	
	--Check if there is a salutation for this PartyID
	SELECT @AddressingText =ps.Salutation
	FROM Sample.Party.PartySalutations ps
	WHERE ps.PartyID=@PartyID	

	--TASK 538 -----------------------------------------------------------------------------

	--Check if Salutation from sample has been overriden/flagged as not to use
	SELECT @OverrideAddressingText = V.OverrideSample_Salutation
	FROM Sample.dbo.vwBrandMarketQuestionnaireSampleMetadata V
	WHERE QuestionnaireRequirementID = @QuestionnaireRequirementID

	--Remove Loaded Salutation if overriden.
	SELECT @AddressingText = NULL
	WHERE @OverrideAddressingText = 1 
	-----------------------------------------------------------------------------------------

	
	--If there isn't any salutation or AddressingTypeID=2 continue normal addressing procedure
	IF ISNULL(@AddressingText,N'')= '' OR  @AddressingTypeID=2
	BEGIN
	
		-- GET THE PATTERN FOR PERSON PARTIES
		IF @Person = 1
		BEGIN

			-- GET THE PERSON DETAILS
			SELECT
				@TitleID = T.TitleID, 
				@Title = T.Title, 
				@FirstName = LTRIM(RTRIM(ISNULL(NULLIF(P.FirstName, '.'), N''))),  -- SOME FIRST NAMES ARE JUST "." - THESE NEED TO BE REMOVED
				@Initials = LTRIM(RTRIM(P.Initials)), 
				@LastName = LTRIM(RTRIM(P.LastName)), 
				@SecondLastName = LTRIM(RTRIM(P.SecondLastName)), 
				@GenderID = P.GenderID
			FROM Party.People P
			INNER JOIN Party.Titles T ON T.TitleID = P.TitleID
			WHERE P.PartyID = @PartyID
			
			-- GET THE PATTERN BASED ON THE PERSON INFORMATION
			SELECT @AddressingPatternID = PAP.PersonAddressingPatternID
			FROM Party.PersonAddressingPatterns PAP
			INNER JOIN ContactMechanism.Countries C ON C.CountryID = PAP.CountryID
			WHERE PAP.QuestionnaireRequirementID = @QuestionnaireRequirementID
			AND PAP.AddressingTypeID = @AddressingTypeID
			AND (
				PAP.TitleID = @TitleID
				OR PAP.TitleID IS NULL
			)
			AND (
				PAP.LanguageID = ISNULL(@LanguageID, C.DefaultLanguageID)
				OR PAP.LanguageID IS NULL
			)
			AND (
				PAP.GenderID = @GenderID
				OR NULLIF(PAP.GenderID, 0) IS NULL
			)
			
			-- IF WE'VE NOT GOT A PATTERN YET USE THE DEFAULT VALUE IF THERE IS ONE
			IF @AddressingPatternID IS NULL
			BEGIN
			
				SELECT @AddressingPatternID = PersonAddressingPatternID
				FROM Party.PersonAddressingPatterns
				WHERE QuestionnaireRequirementID = @QuestionnaireRequirementID
				AND AddressingTypeID = @AddressingTypeID
				AND DefaultAddressing = 1
				
			END
			
			-- NOW GET THE ADDRESSING TEXT
			SELECT @AddressingText = Pattern FROM Party.PersonAddressingPatterns WHERE PersonAddressingPatternID = @AddressingPatternID
			
			-- FINALLY IF THE AddressingText IS NULL THEN USE THE DEFAULT FOR THE AddressingType
			IF @AddressingText IS NULL
			BEGIN
				SELECT @AddressingText = Pattern
				FROM Party.AddressingPatternDefaults
				WHERE AddressingTypeID = @AddressingTypeID
			END

			-- CHECK FOR MISSING ELEMENTS
			DECLARE @MissingElements BIT
			
			SELECT @MissingElements = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
			FROM Party.vwPersonAddressingElements
			WHERE PersonAddressingPatternID = ISNULL(@AddressingPatternID, 0)
			AND QuestionnaireRequirementID = @QuestionnaireRequirementID
			AND AddressingTypeID = @AddressingTypeID
			AND CASE
					WHEN (NULLIF(@Title, N'') IS NULL AND CHARINDEX('@Title', AddressElement) > 0) THEN 1
					WHEN (NULLIF(@FirstName, N'') IS NULL AND NULLIF(@Initials, N'') IS NULL AND CHARINDEX('@Initials', AddressElement) > 0 AND CHARINDEX('@FirstName', AddressElement) > 0) THEN 1
					WHEN (NULLIF(@FirstName, N'') IS NULL AND CHARINDEX('@FirstName', AddressElement) > 0) THEN 1
					WHEN (NULLIF(@MiddleName, N'') IS NULL AND CHARINDEX('@MiddleName', AddressElement) > 0) THEN 1
					WHEN (NULLIF(@LastName, N'') IS NULL AND CHARINDEX('@LastName', AddressElement) > 0) THEN 1
					WHEN (NULLIF(@SecondLastName, N'') IS NULL AND CHARINDEX('@SecondLastName', AddressElement) > 0) THEN 1
					ELSE 0
				END > 0
			
			-- IF WE ARE MISSING REQUIRED ELEMENTS FROM THE PERSON DETAILS THEN WE TRY TO USE THE ORGANISATION DETAILS
			IF @MissingElements = 1
			BEGIN
				SET @Organisation = 1
				SET @Person = 0
			END		
		END
		
		-- GET THE PATTERN FOR ORGANISATION PARTIES
		IF @Organisation = 1
		BEGIN
		
			-- GET THE ORGANISATION NAME
			SELECT @OrganisationName = OrganisationName
			FROM Party.Organisations
			WHERE PartyID = @PartyID
			
			-- RESET THE @AddressingPatternID
			SET @AddressingPatternID = NULL
			SET @AddressingText = NULL
			
			-- GET THE PATTERN BASED ON THE ORGANISATION NAME
			SELECT @AddressingPatternID = OAP.OrganisationAddressingPatternID
			FROM Party.OrganisationAddressingPatterns OAP
			INNER JOIN ContactMechanism.Countries C ON C.CountryID = OAP.CountryID
			WHERE OAP.QuestionnaireRequirementID = @QuestionnaireRequirementID
			AND OAP.AddressingTypeID = @AddressingTypeID
			AND (
				OAP.LanguageID = ISNULL(@LanguageID, C.DefaultLanguageID)
				OR OAP.LanguageID IS NULL
			)
			
			-- NOW GET THE ADDRESSING TEXT
			SELECT @AddressingText = Pattern FROM Party.OrganisationAddressingPatterns WHERE OrganisationAddressingPatternID = @AddressingPatternID
			
		END

		-- NOW REPLACE THE PLACEHODERS WITH THE REQUIRED VALUES
		SET @AddressingText = REPLACE(@AddressingText, '@TitleENGToBRA', CASE @Title
																	WHEN N'Mr' THEN N'Sr'
																	WHEN N'Mrs' THEN N'Sra'
																	WHEN N'Ms' THEN N'Sra'
																	ELSE N''
																END)
		SET @AddressingText = REPLACE(@AddressingText, '@TitleHerrToHerrn', REPLACE(ISNULL(@Title, N''), N'Herr', N'Herrn'))
		SET @AddressingText = REPLACE(@AddressingText, '@Title', ISNULL(@Title, N''))
		SET @AddressingText = REPLACE(@AddressingText, '@FirstName/@Initials', COALESCE(NULLIF(@FirstName, N''), NULLIF(@Initials, N''), N''))
		SET @AddressingText = REPLACE(@AddressingText, '@Initials/@FirstName', COALESCE(NULLIF(@Initials, N''), NULLIF(@FirstName, N''), N''))
		SET @AddressingText = REPLACE(@AddressingText, '@FirstName', ISNULL(@FirstName, N''))
		SET @AddressingText = REPLACE(@AddressingText, '@LastName', ISNULL(@LastName, N''))
		SET @AddressingText = REPLACE(@AddressingText, '@SecondLastName', ISNULL(@SecondLastName, N''))
		SET @AddressingText = REPLACE(@AddressingText, '@OrganisationName', ISNULL(@OrganisationName, N''))
		SET @AddressingText = REPLACE(LTRIM(RTRIM(@AddressingText)), N'  ', N' ')
		SET @AddressingText = REPLACE(@AddressingText, N' ,', N',')
		
	END 
	
	IF @AddressingText = 'Dear Sir/Madam'
	Begin
		
		IF (@Person = 1) AND
			ISNULL(@Title, N'') ='' AND
			ISNULL(@FirstName, N'') <> '' AND 
			ISNULL(@LastName, N'') <>'' 
				SET @AddressingText = 'Dear ' + @FirstName + ' ' + @LastName  


		IF (@Person = 1) AND
			ISNULL(@FirstName, N'') <> '' AND 
			ISNULL(@LastName, N'')  = '' 
				SET @AddressingText = 'Dear ' + @FirstName

	END
	-- RETURN THE SALUTATION
	RETURN(ISNULL(@AddressingText, ''))


END