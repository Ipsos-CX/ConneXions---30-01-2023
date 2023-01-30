CREATE PROCEDURE [OWAPv2].[uspGetCustomerDetailsFromCountryRegionPostCode]
	@CountryID [dbo].[CountryID]=N'', 
	@Region [dbo].[NameDetail]=N'', 
	@PostCode [dbo].[Postcode]=N'', 
	@RowCount INT OUTPUT, 
	@ErrorCode INT OUTPUT
AS

/*
	Purpose:	Returns the dataset for customer based on Country, Region and PostCode
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Pardip Mudhar		Created
	1.1				14/09/2016		Chris Ross			Move to schema OWAPv2
	1.2				10/05/2018		Chris Ross			BUG 14399 - Add in filter to ensure Person is not GDPR erased
	1.3				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.	
*/


SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @FirstName			NVARCHAR(255)
	DECLARE @Initials			NVARCHAR(255)
	DECLARE @LastName			NVARCHAR(255)
	DECLARE @OrganisationName	NVARCHAR(255)
	
	SET @RowCount = 0
	SET @ErrorCode = 0
	--
	-- VALIDATE THE PARAMETERS
	--
	SET @FirstName = LTRIM(RTRIM(ISNULL(@FirstName, N'')))
	SET @Initials = LTRIM(RTRIM(ISNULL(@Initials, N'')))
	SET @LastName = LTRIM(RTRIM(ISNULL(@LastName, N'')))
	SET @OrganisationName = LTRIM(RTRIM(ISNULL(@OrganisationName, N'')))
	SET @PostCode = LTRIM(RTRIM(ISNULL(@PostCode, N'')))
	--
	-- GET THE EMPLOYEE AND EMPLOYER RoleTypeIDs
	--
	DECLARE @EmployerRoleTypeID dbo.RoleTypeID
	DECLARE @EmployeeRoleTypeID dbo.RoleTypeID

	SELECT @EmployerRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employer'
	SELECT @EmployeeRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employee'

		SELECT DISTINCT
			P.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(PO.OrganisationName, N'') AS CompanyName,
			ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails
		FROM ContactMechanism.PostalAddresses PA
			INNER JOIN ContactMechanism.PartyContactMechanisms PCM on PCM.ContactMechanismID = PA.ContactMechanismID
			INNER JOIN Party.Parties P ON P.PartyID = PCM.PartyID
			INNER JOIN Party.People PP ON PP.PartyID = P.PartyID
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID
					LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PA.ContactMechanismID = PBPA.ContactMechanismID
			LEFT JOIN Party.PartyRelationships PR INNER JOIN Party.Organisations PO 
				ON PO.PartyID = PR.PartyIDTo
				ON PR.PartyIDFrom = P.PartyID
				AND PR.RoleTypeIDTo = 3
				AND PR.RoleTypeIDFrom = 4
		WHERE PA.CountryID = @CountryID
		AND UPPER(PA.Region) = 
			CASE @Region
				WHEN N'NULL' THEN NULL
				ELSE UPPER(@Region)
			END
		AND UPPER(pa.PostCode) =
			CASE @PostCode 
				WHEN N'NULL' THEN NULL
				ELSE UPPER(@PostCode)
			END
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.2
						WHERE er.PartyID = PP.PartyID)
		
		
		SET @RowCount = @@ROWCOUNT

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

