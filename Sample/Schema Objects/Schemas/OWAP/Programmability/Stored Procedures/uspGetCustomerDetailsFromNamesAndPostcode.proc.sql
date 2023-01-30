CREATE PROCEDURE OWAP.uspGetCustomerDetailsFromNamesAndPostcode
(
	 @FirstName dbo.NameDetail = N''
	,@Initials dbo.NameDetail = N''
	,@LastName dbo.NameDetail = N''
	,@OrganisationName dbo.OrganisationName = N''
	,@PostCode dbo.PostCode = N''
	,@RowCount INT OUTPUT
	,@ErrorCode INT OUTPUT	
)

AS

/*
	Purpose:	Search for a customer given their name, company and/or postcode details
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SET @RowCount = 0
	SET @ErrorCode = 0

	-- VALIDATE THE PARAMETERS
	SET @FirstName = LTRIM(RTRIM(ISNULL(@FirstName, N'')))
	SET @Initials = LTRIM(RTRIM(ISNULL(@Initials, N'')))
	SET @LastName = LTRIM(RTRIM(ISNULL(@LastName, N'')))
	SET @OrganisationName = LTRIM(RTRIM(ISNULL(@OrganisationName, N'')))
	SET @PostCode = LTRIM(RTRIM(ISNULL(@PostCode, N'')))
	
	-- WE MUST HAVE A LAST NAME OR ORGANISATION NAME TO DO THE SEARCH SO CHECK THAT THESE HAVE BEEN PROVIDED
	IF LEN(@LastName + @OrganisationName) = 0
	BEGIN
		SET @ErrorCode = 60201
		RAISERROR(60201, 1, 1)
		RETURN
	END
		

	-- GET THE EMPLOYEE AND EMPLOYER RoleTypeIDs
	DECLARE @EmployerRoleTypeID dbo.RoleTypeID
	DECLARE @EmployeeRoleTypeID dbo.RoleTypeID

	SELECT @EmployerRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employer'
	SELECT @EmployeeRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employee'

	-- PERFORM THE CHECK USING THE PERSON DETAILS ONLY
	IF LEN(@LastName) > 0 AND LEN(@OrganisationName) = 0 AND LEN(@PostCode) = 0
	BEGIN
		SELECT DISTINCT
			P.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(PO.OrganisationName, N'') AS CompanyName,
			ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails
		FROM Party.Parties P
		INNER JOIN Party.People PP ON PP.PartyID = P.PartyID
		INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
		LEFT JOIN Party.PartyRelationships PR
			INNER JOIN Party.Organisations PO ON PO.PartyID = PR.PartyIDTo
		ON PR.PartyIDFrom = P.PartyID
		AND PR.RoleTypeIDTo = @EmployerRoleTypeID
		AND PR.RoleTypeIDFrom = @EmployeeRoleTypeID
		LEFT JOIN Meta.PartyBestPostalAddresses PBPA
			INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
		ON PBPA.PartyID = P.PartyID
		WHERE CASE
				WHEN @FirstName = N'' THEN ISNULL(PP.FirstName, '')
				ELSE @FirstName
			END = ISNULL(PP.FirstName, '')
		AND CASE
				WHEN @Initials = N'' THEN ISNULL(PP.Initials, '')
				ELSE @Initials
			END = ISNULL(PP.Initials, '')
		AND CASE
				WHEN @LastName = N'' THEN ISNULL(PP.LastName, '')
				ELSE @LastName
			END = ISNULL(PP.LastName, '')
		
		SET @RowCount = @@ROWCOUNT
	END


	-- PERFORM THE CHECK USING THE ORGANISATION DETAILS ONLY
	IF LEN(@LastName) = 0 AND LEN(@OrganisationName) > 0 AND LEN(@PostCode) = 0
	BEGIN
		SELECT DISTINCT
			P.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, N'') AS CompanyName,
			ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails
		FROM Party.Parties P
		INNER JOIN Party.Organisations O ON O.PartyID = P.PartyID
		LEFT JOIN Party.PartyRelationships PR
			INNER JOIN Party.People PP ON PP.PartyID = PR.PartyIDFrom
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
		ON PR.PartyIDTo = P.PartyID
		AND PR.RoleTypeIDTo = @EmployerRoleTypeID
		AND PR.RoleTypeIDFrom = @EmployeeRoleTypeID
		LEFT JOIN Meta.PartyBestPostalAddresses PBPA
			INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
		ON PBPA.PartyID = P.PartyID
		WHERE O.OrganisationName = @OrganisationName
		
		SET @RowCount = @@ROWCOUNT
	END

	-- PERFORM THE CHECK USING THE POST CODE PLUS THE LAST NAME OR ORGANISATION NAME
	IF LEN(@PostCode) > 0
	BEGIN
		SELECT DISTINCT
			PCM.PartyID,
			Party.udfGetFullName(
				ISNULL(T.Title, OT.Title),
				ISNULL(PP.FirstName, OP.FirstName),
				ISNULL(PP.Initials, OP.Initials),
				ISNULL(PP.MiddleName, OP.MiddleName),
				ISNULL(PP.LastName, OP.LastName),
				ISNULL(PP.SecondLastName, OP.SecondLastName)
			) AS FullName,
			COALESCE(O.OrganisationName, PO.OrganisationName, '') AS CompanyName,
			ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PA.ContactMechanismID, 0)) AS OtherDetails
		FROM ContactMechanism.PostalAddresses PA
		INNER JOIN ContactMechanism.PartyContactMechanisms PCM ON PCM.ContactMechanismID = PA.ContactMechanismID
		LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
			LEFT JOIN Party.PartyRelationships PRO
				INNER JOIN Party.Organisations PO ON PO.PartyID = PRO.PartyIDTo
												AND PRO.RoleTypeIDFrom = @EmployeeRoleTypeID
												AND PRO.RoleTypeIDTo = @EmployerRoleTypeID
			ON PRO.PartyIDFrom = PP.PartyID
		ON PP.PartyID = PCM.PartyID
		LEFT JOIN Party.Organisations O ON O.PartyID = PCM.PartyID
		LEFT JOIN Party.PartyRelationships PRP
			INNER JOIN Party.People OP ON OP.PartyID = PRP.PartyIDFrom
										AND PRP.RoleTypeIDFrom = @EmployeeRoleTypeID
										AND PRP.RoleTypeIDTo = @EmployerRoleTypeID
			INNER JOIN Party.Titles OT ON OT.TitleID = OP.TitleID
		ON PRP.PartyIDTo = O.PartyID
		WHERE PA.PostCode = @PostCode
		AND CASE
				WHEN LEN(@OrganisationName) > 0 THEN COALESCE(O.OrganisationName, PO.OrganisationName, '')
				ELSE @OrganisationName
		END = @OrganisationName
		AND CASE
				WHEN LEN(@FirstName) > 0 THEN COALESCE(PP.FirstName, OP.FirstName, '')
				ELSE @FirstName
		END = @FirstName
		AND CASE
				WHEN LEN(@Initials) > 0 THEN COALESCE(PP.Initials, OP.Initials, '')
				ELSE @Initials
		END = @Initials
		AND CASE
				WHEN LEN(@LastName) > 0 THEN COALESCE(PP.LastName, OP.LastName, '')
				ELSE @LastName
		END = @LastName
		
		SET @RowCount = @@ROWCOUNT
	END

END TRY
BEGIN CATCH

	SET @ErrorCode = @@Error

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	