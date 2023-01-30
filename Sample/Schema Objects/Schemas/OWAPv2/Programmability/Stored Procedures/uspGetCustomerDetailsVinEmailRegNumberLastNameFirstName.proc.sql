CREATE PROCEDURE [OWAPv2].[uspGetCustomerDetailsVinEmailRegNumberLastNameFirstName]
@PartyID [dbo].[PartyID]=NULL, @CaseID [dbo].[CaseID]=NULL, @FirstName [dbo].[NameDetail]=N'', @RegNumber [dbo].[RegistrationNumber]=N'', @EmailAddress [dbo].[EmailAddress]=N'', @VIN [dbo].[VIN]=N'', @LastName [dbo].[NameDetail]=N'', @RowCount INT OUTPUT, @ErrorCode INT OUTPUT
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

/*
	Purpose:	Returns the dataset for customer based on ANY combination of VIN, Email, Reg NUmber, Last Name, First Name
		
	Release			Version			Date			Developer			Comment
	LIVE			1.0				20092018		Ben King			BUG 14837
	LIVE			1.1				21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
	LIVE			1.2				29-03-2022		Ben King			TASK 749 - OWAP search SP - add support for wild card characters
*/

BEGIN TRY

	SET @RowCount = 0
	SET @ErrorCode = 0

	-- VALIDATE THE PARAMETERS
	SET @LastName = LTRIM(RTRIM(ISNULL(@LastName, N'')))
	SET @VIN = LTRIM(RTRIM(ISNULL(@VIN, N'')))
	SET @RegNumber = LTRIM(RTRIM(ISNULL(@RegNumber, N'')))
	SET @EmailAddress = LTRIM(RTRIM(ISNULL(@EmailAddress, N'')))
	SET @FirstName = LTRIM(RTRIM(ISNULL(@FirstName, N'')))

	-- WE MUST HAVE ONE OF THE 5 SEARCH PARAMETERS
	IF LEN(@LastName + @VIN + @RegNumber + @EmailAddress + @FirstName) = 0
	BEGIN
		SET @ErrorCode = 60201
		RAISERROR(60201, 1, 1)
		RETURN
	END
		
	-- GET THE EMPLOYEE AND EMPLOYER RoleTypeIDs
	DECLARE @EmployerRoleTypeID NVARCHAR(MAX) 
	DECLARE @EmployeeRoleTypeID NVARCHAR(MAX) 

	SELECT @EmployerRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employer'
	SELECT @EmployeeRoleTypeID = RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'Employee'

	DECLARE @SQL1 NVARCHAR(MAX) 
	DECLARE @FILT1 NVARCHAR(MAX) 
	DECLARE @FILT2 NVARCHAR(MAX) 

	-- BUILD FILTER
	IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ONLY
		BEGIN
			--SET @FILT1 = N''
			--SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''

			-- V1.2
			IF CHARINDEX('%', @EmailAddress) > 0
				BEGIN
					SET @FILT1 = N' WHERE CE.EmailAddress LIKE ''' + @EmailAddress + ''''
					SET @FILT2 = N''
				END
			IF CHARINDEX('%', @EmailAddress) = 0
				BEGIN
					SET @FILT1 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
					SET @FILT2 = N''
				END

		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --JUST LASTNAME
		BEGIN

			--SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''''
			--SET @FILT2 = N''

			-- V1.2
			IF CHARINDEX('%', @LastName) > 0
				BEGIN
					SET @FILT1 = N' WHERE PP.LASTNAME LIKE ''' + @LastName + ''''
					SET @FILT2 = N''
				END
			IF CHARINDEX('%', @LastName) = 0
				BEGIN
					SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LastName + ''''
					SET @FILT2 = N''
				END

		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --JUST VIN
		BEGIN
			--SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + ''''
			--SET @FILT2 = N''

			-- V1.3
			IF CHARINDEX('%', @VIN) > 0
				BEGIN
					SET @FILT1 = N' WHERE V.VIN LIKE ''' + @VIN + ''''
					SET @FILT2 = N''
				END
			IF CHARINDEX('%', @VIN) = 0
				BEGIN
					SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + ''''
					SET @FILT2 = N''
				END

		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --JUST REG NUMBER
		BEGIN
			--SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + ''''
			--SET @FILT2 = N''

			-- V1.3
			IF CHARINDEX('%', @RegNumber) > 0
				BEGIN
					SET @FILT1 = N' WHERE R.RegistrationNumber LIKE ''' + @RegNumber + ''''
					SET @FILT2 = N''
				END
			IF CHARINDEX('%', @RegNumber) = 0
				BEGIN
					SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + ''''
					SET @FILT2 = N''
				END

		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND V.VIN = ''' + @VIN + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME & VIN & REG NUMBER
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND V.VIN = ''' + @VIN + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & VIN 
		BEGIN
			SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + ''''
			SET @FILT2 =  N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & VIN & REGNO
		BEGIN
			SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 =  N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   --EMAIL ADDRESS & REG NUMBER 
		BEGIN
			SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + ''''
			SET @FILT2 =  N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- REG NUMBER & LAST NAME
		BEGIN
			SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + ''' AND PP.LASTNAME = ''' + @LASTNAME + ''''
			SET @FILT2 =  N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- REG NUMBER & LAST NAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND V.VIN = ''' + @VIN + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- LAST NAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND V.VIN = ''' + @VIN + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- LAST NAME & REGNUMBER
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND R.RegistrationNumber = ''' + @RegNumber + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- VIN & REGNUMBER
		BEGIN
			SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + ''' AND V.VIN = ''' + @VIN + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) = 0 AND @PartyID IS NULL AND @CaseID IS NULL   -- EMAIL & LAST NAME & REGNUMBER
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + ''' AND R.RegistrationNumber = ''' + @RegNumber + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME & VIN & REG NUMBER & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + '''  AND V.VIN = ''' + @VIN + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME & REG NUMBER & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS & LASTNAME  & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + '''  AND PP.FIRSTNAME = ''' + @FirstName  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL ADDRESS  & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --LASTNAME & VIN & REG NUMBER & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LASTNAME + '''  AND V.VIN = ''' + @VIN + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --VIN & REG NUMBER & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --VIN & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE V.VIN = ''' + @VIN + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --FIRST NAME
		BEGIN
			--SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''''
			--SET @FILT2 = N''

			-- V1.3
			IF CHARINDEX('%', @FirstName) > 0
				BEGIN
					SET @FILT1 = N' WHERE PP.FIRSTNAME LIKE ''' + @FirstName + ''''
					SET @FILT2 = N''
				END
			IF CHARINDEX('%', @FirstName) = 0
				BEGIN
					SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''''
					SET @FILT2 = N''
				END

		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --REG NUM & FIRST NAME 
		BEGIN
			SET @FILT1 = N' WHERE R.RegistrationNumber = ''' + @RegNumber + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --LAST NAME & REG NUMBER & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LastName + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --LAST NAME & FIRST NAME
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LastName + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) = 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --LAST NAME & FIRST NAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.LASTNAME = ''' + @LastName + '''  AND PP.FIRSTNAME = ''' + @FirstName + ''' AND V.VIN = ''' + @VIN  + ''''
			SET @FILT2 = N''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL & FIRST NAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''' AND V.VIN = ''' + @VIN  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) > 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) = 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL & FIRST NAME & LAST NAME & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''' AND PP.LASTNAME = ''' + @LastName + ''' AND V.VIN = ''' + @VIN  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) = 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL & FIRST NAME & REG
		BEGIN
			SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END
	ELSE IF LEN(@EmailAddress) > 0 AND LEN(@LastName) = 0 AND LEN(@VIN) > 0 AND LEN(@RegNumber) > 0 AND LEN(@FirstName) > 0 AND @PartyID IS NULL AND @CaseID IS NULL  --EMAIL & FIRST NAME & REG & VIN
		BEGIN
			SET @FILT1 = N' WHERE PP.FIRSTNAME = ''' + @FirstName + ''' AND R.RegistrationNumber = ''' + @RegNumber  + ''' AND V.VIN = ''' + @VIN  + ''''
			SET @FILT2 = N' WHERE CE.EmailAddress = ''' + @EmailAddress + ''''
		END

	SET @SQL1 = 
	N';WITH ResultSet1 (PartyID, Title, FirstName, MiddleName, LastName, SecondLastName, BirthDate, OrganisationName, Market, VIN,  VehicleID, RegNum) AS
				(	
					SELECT DISTINCT
								P.PartyID,
								T.Title,
								PP.FirstName,
								PP.MiddleName,
								PP.LastName,
								PP.SecondLastName,
								--Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
								--ISNULL(PO.OrganisationName, N'''') AS CompanyName,
								--ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) AS OtherDetails,
								ISNULL(CONVERT(NVARCHAR(24), PP.BirthDate, 103), N'''') AS BirthDate,
								ISNULL(OS.OrganisationName,'''') AS OrganisationName,
								ISNULL(CN.Country,'''') AS Market,
								ISNULL(V.VIN, '''') AS VIN,
								V.VehicleID AS VehicleID,
								ISNULL(R.RegistrationNumber, '''') AS RegNum	
					FROM Party.Parties P
								LEFT JOIN Party.People PP ON PP.PartyID = P.PartyID
								LEFT JOIN Party.Organisations OS ON OS.PartyID = P.PartyID
								LEFT JOIN Party.Titles T ON T.TitleID = PP.TitleID
								INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.PartyID = P.PartyID --
								INNER JOIN Vehicle.Vehicles V ON V.VehicleID = VPRE.VehicleID --
								INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID --
								LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
											INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID 
										ON VRE.VehicleID = V.VehicleID
										AND VPRE.EventID = VRE.EventID
								LEFT JOIN Party.PartyRelationships PR
									INNER JOIN Party.Organisations PO ON PO.PartyID = PR.PartyIDTo
								ON PR.PartyIDFrom = P.PartyID
								AND PR.RoleTypeIDTo =' + @EmployerRoleTypeID +
								' AND PR.RoleTypeIDFrom =' + @EmployeeRoleTypeID + 
								' LEFT JOIN Meta.PartyBestPostalAddresses PBPA
									INNER JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
								ON PBPA.PartyID = P.PartyID
								LEFT JOIN Party.Genders PG ON ISNULL(NULLIF(PP.GenderID,''''),0) = PG.GenderID
								LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID '
								+ @FILT1 + N'
								
				),
		ResultSet2 (PartyID, Title,FirstName, MiddleName, LastName, SecondLastName, BirthDate, OrganisationName, Market, VIN,  VehicleID, RegNum, EmailAddress) AS
				(
					SELECT DISTINCT 
								R.PartyID,
								R.Title,
								R.FirstName,
								R.MiddleName,
								R.LastName,
								R.SecondLastName,
								R.BirthDate,
								R.OrganisationName,
								R.Market,
								R.VIN,
								R.VehicleID,
								R.RegNum,
								CE.EmailAddress 
					FROM ResultSet1 R
								LEFT JOIN ContactMechanism.PartyContactMechanisms PCM 
								INNER JOIN ContactMechanism.EmailAddresses CE ON CE.ContactMechanismID = PCM.ContactMechanismID 
								ON PCM.PartyID = R.PartyID '
								+ @FILT2 + N'
					
				)
				SELECT DISTINCT
				R2.*,
				CASE WHEN VPR.ThroughDate IS NOT NULL THEN ''SOLD'' ELSE ''LIVE'' END AS SOLD
				FROM ResultSet2 R2
								INNER JOIN  Vehicle.VehiclePartyRoles VPR ON VPR.VehicleID = R2.VehicleID
																	  AND VPR.PartyID = R2.PartyID
																	  
				WHERE NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er
									WHERE er.PartyID = R2.PartyID)
				AND (R2.LastName IS NOT NULL OR R2.OrganisationName <>'''')'


																	
	EXECUTE sp_executesql @SQL1
	
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


GO