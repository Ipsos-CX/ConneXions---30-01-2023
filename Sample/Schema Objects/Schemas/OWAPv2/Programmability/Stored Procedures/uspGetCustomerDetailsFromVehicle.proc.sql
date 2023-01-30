CREATE PROCEDURE [OWAPv2].[uspGetCustomerDetailsFromVehicle]
(
	 @VIN dbo.VIN
	,@VINPrefix dbo.VINPrefix
	,@ChassisNumber dbo.ChassisNumber
	,@RegNumber dbo.RegistrationNumber
	,@RowCount INT OUTPUT
	,@ErrorCode INT OUTPUT	
)

AS

/*
	Purpose:	Search for a customer given their vehicle details
		
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Eddie Thomas		Created from [OWAP].[uspGetCustomerDetailsFromVehicle] 
	1.1			10/05/2018		Chris Ross			BUG 14399 - Filter out GDPR erase customers.  Remove dupes linkages on VIN search.
	1.2			21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
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

	CREATE TABLE #SEARCHDATA
	(
		SearchedON NVARCHAR(50) null,
		ParytID BIGINT null,
		Title NVARCHAR(255) null,
		FirstName NVARCHAR(255) null,
		MiddleName NVARCHAR(255) null,
		LastName NVARCHAR(255) null,
		SecondLastName NVARCHAR(255) null,
		FullName NVARCHAR(255) null,
		CompanyName NVARCHAR(255) null,
		OtherDetails NVARCHAR(1024),
		Market NVARCHAR(255) null
	)
	--
	-- Get search data for vin only
	--		
	IF ( LEN( @VIN) > 0 ) 
	BEGIN
		INSERT INTO #SEARCHDATA
		SELECT DISTINCT
			'VIN',
			VPRE.PartyID ,
			T.Title,
			PP.FirstName,
			PP.MiddleName,
			PP.LastName,
			PP.SecondLastName,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + '] [' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '') + '] 'AS OtherDetails,
			
			CASE
				 WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
				 WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
			
		FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
		
			LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
					INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID 
				ON VRE.VehicleID = V.VehicleID
				AND VPRE.EventID = VRE.EventID				-- v1.1 - Remove dupe linkages
		
			LEFT JOIN Party.People PP
					INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID 
				ON PP.PartyID = VPRE.PartyID
			
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
		
		WHERE VIN = @VIN
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
				WHERE er.PartyID = VPRE.PartyID)
	END		
	--
	-- Get search data for reg number
	--
	IF ( LEN(@RegNumber) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		SELECT DISTINCT
			'RegNo',
			VPRE.PartyID,
			T.Title,
			PP.FirstName,
			PP.MiddleName,
			PP.LastName,
			PP.SecondLastName,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + '] [' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			CASE
				 WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
				 WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
			
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
														   AND VPRE.EventID = VRE.EventID  -- v1.1 -- Remove dupe linkage
			LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
			
			
		WHERE 
 			R.RegistrationNumber = @RegNumber
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
				WHERE er.PartyID = VPRE.PartyID)
	END		
	--
	-- get search data based on vinprefix and this search is based on like as we return data for browsing
	--	
	IF ( LEN(@VinPrefix) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		SELECT DISTINCT
			'VinPrefix',
			VPRE.PartyID,
			T.Title,
			PP.FirstName,
			PP.MiddleName,
			PP.LastName,
			PP.SecondLastName,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + '] [' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '') + ']' AS OtherDetails,
			CASE
				 WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
				 WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
														  AND VPRE.EventID = VRE.EventID  -- v1.1 -- Remove dupe linkage

			LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
					
		WHERE 
			V.VINPrefix = @VinPrefix
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
				WHERE er.PartyID = VPRE.PartyID)
		--
		-- get search data based on vinprefix and this search is based on like as we return data for browsing
		-- if no data is found on vinprefix search using vin
		--	
			INSERT INTO #SEARCHDATA
			SELECT DISTINCT
				'VINVinPrefix',
				VPRE.PartyID,
				T.Title,
				PP.FirstName,
				PP.MiddleName,
				PP.LastName,
				PP.SecondLastName,
				Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
				ISNULL(O.OrganisationName, '') AS CompanyName,
				'[' + CONVERT( NVARCHAR(50), V.VehicleID) + '] [' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '') + ']' AS OtherDetails,
				CASE
					WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
					WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
			FROM Vehicle.Registrations R
				INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
				INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
				INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
														      AND VPRE.EventID = VRE.EventID  -- v1.1 -- Remove dupe linkage

				LEFT JOIN Party.People PP
				INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
				LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
				
				LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
				LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
				LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
				
				LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
				LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
				LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
			WHERE 
				V.VIN LIKE @VinPrefix+'%'
				AND V.VINPrefix <> @VinPrefix
			AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
					WHERE er.PartyID = VPRE.PartyID)
	END		
	--
	-- get search data based on chasis number and this search is based on like as we return data for browsing
	--	
	IF ( LEN(@ChassisNumber) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		SELECT DISTINCT
			'ChassisNumber',
			VPRE.PartyID,
			T.Title,
			PP.FirstName,
			PP.MiddleName,
			PP.LastName,
			PP.SecondLastName,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + '] [' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '') + ']' AS OtherDetails,
			CASE
				 WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
				 WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
														  AND VPRE.EventID = VRE.EventID  -- v1.1 -- Remove dupe linkage
			
			LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
			
			LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
			LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
			LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
		WHERE 
			V.ChassisNumber = @ChassisNumber
		AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
				WHERE er.PartyID = VPRE.PartyID)
			
			INSERT INTO #SEARCHDATA
			SELECT DISTINCT
				'VINChassisNumber',
				VPRE.PartyID,
				T.Title,
				PP.FirstName,
				PP.MiddleName,
				PP.LastName,
				PP.SecondLastName,
				Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
				ISNULL(O.OrganisationName, '') AS CompanyName,
				'[' + ISNULL(V.VIN, '') + '] [' + M.ModelDescription + '] [' + ISNULL(R.RegistrationNumber, '') + '] ' AS OtherDetails,  
				CASE
				 WHEN NULLIF(CN.Country,'') IS NOT NULL THEN CN.Country
				 WHEN NULLIF(CN2.Country,'') IS NOT NULL THEN CN2.Country 
				 ELSE ''
			END AS Market 
			FROM Vehicle.Registrations R
				INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
				INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
				INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID 
														  AND VPRE.EventID = VRE.EventID  -- v1.1 -- Remove dupe linkage
				
				LEFT JOIN Party.People PP
				INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
				LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
				
				LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON PBPA.PartyID = PP.PartyID
				LEFT JOIN ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = PBPA.ContactMechanismID
				LEFT JOIN ContactMechanism.Countries CN ON CN.CountryID = PA.CountryID
				
				LEFT JOIN Meta.PartyBestPostalAddresses PBPA2 ON PBPA2.PartyID = O.PartyID
				LEFT JOIN ContactMechanism.PostalAddresses PA2 ON PA2.ContactMechanismID = PBPA2.ContactMechanismID
				LEFT JOIN ContactMechanism.Countries CN2 ON CN2.CountryID = PA2.CountryID
				
			WHERE 
				V.VIN LIKE '%'+@ChassisNumber
				AND V.ChassisNumber <> @ChassisNumber
			AND NOT EXISTS (SELECT er.PartyID FROM [$(AuditDB)].GDPR.ErasureRequests er				-- v1.1
					WHERE er.PartyID = VPRE.PartyID)
	END		
	--
	-- update the text of other details fields and mark it as sold or live
	--

	UPDATE SD
		SET OtherDetails = OtherDetails + ' ['+ContactMechanism.udfGetFormattedPostalAddress(ISNULL(PBPA.ContactMechanismID, 0)) + '] [' + CASE WHEN VPR.ThroughDate IS NOT NULL THEN 'SOLD' ELSE 'LIVE' END + '] '
	FROM #SEARCHDATA SD
	INNER JOIN 
		(
			SELECT DISTINCT PartyID, VehicleID, ThroughDate
			FROM Vehicle.VehiclePartyRoles 
		) AS VPR 
	ON SD.ParytID = VPR.PartyID AND sd.OtherDetails LIKE '[[]'+CONVERT(VARCHAR(50),vpr.VehicleID) +'%'   -- 1.4
	LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON VPR.PartyID = PBPA.PartyID
	
	SELECT * FROM #SEARCHDATA ORDER BY SearchedON
	SELECT @RowCount = @@ROWCOUNT
	DROP TABLE #SEARCHDATA
		
END TRY
BEGIN CATCH

	SET @ErrorCode = @@Error

	SELECT
		 @ErrorNumber = ERROR_NUMBER()
		,@ErrorSeverity = ERROR_SEVERITY()
		,@ErrorState = ERROR_STATE()
		,@ErrorLocation = ERROR_PROCEDURE()
		,@ErrorLine = ERROR_LINE()
		,@ErrorMessage = ERROR_MESSAGE()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
