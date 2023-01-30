CREATE PROCEDURE OWAP.uspGetCustomerDetailsFromVehicle
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
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				06/06/2012		Pardip Mudhar		Modified for New OWAP
	1.2				18/08/2012		pardip Mudhar		Added address details to be returned in the OtherDetails column
	1.3			07/02/2014			Martin Riverol		Amendment to car sold marker. The current logic is losing details for records that do not have a postal address

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
		ID INT IDENTITY(1,1),  
		SearchedON NVARCHAR(50) null,
		ParytID BIGINT null,
		FullName NVARCHAR(255) null,
		CompanyName NVARCHAR(255) null,
		VehicleID NVARCHAR(255) null,
		VIN NVARCHAR(255) null,
		ModelDescription NVARCHAR(255) null,
		RegistrationNumber NVARCHAR(255) null,
		OtherDetails NVARCHAR(255) null,
		VehicleStatus NVARCHAR(255) NULL
	)

	--
	-- Get search data for vin only
	--		
	IF ( LEN( @VIN) > 0 ) 
	BEGIN
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'VIN',
			VPRE.PartyID ,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			CONVERT( NVARCHAR(50), V.VehicleID) AS VehicleID,
			ISNULL(V.VIN, '') AS VIN,
			M.ModelDescription,
			ISNULL(R.RegistrationNumber, '') AS RegistrationNumber,
			'',
			''
		FROM Vehicle.Vehicles V
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			LEFT JOIN Vehicle.VehicleRegistrationEvents VRE
			INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
		WHERE VIN = @VIN
	END		
	--
	-- Get search data for reg number
	--
	IF ( LEN(@RegNumber) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'RegNo',
			VPRE.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			V.VehicleID,
			V.VIN,
			M.ModelDescription,
			R.RegistrationNumber,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + ']' + '[' + ISNULL(V.VIN, '') + ']' + '[' + M.ModelDescription + ']' + '[' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			''
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
		WHERE 
 			R.RegistrationNumber = 'HN57DVC'
	END		
	--
	-- get search data based on vinprefix and this search is based on like as we return data for browsing
	--	
	IF ( LEN(@VinPrefix) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'VinPrefix',
			VPRE.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			V.VehicleID,
			V.VIN,
			M.ModelDescription,
			R.RegistrationNumber,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + ']' + '[' + ISNULL(V.VIN, '') + ']' + '[' + M.ModelDescription + ']' + '[' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			''		
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
		WHERE 
			V.VINPrefix = @VinPrefix
		--
		-- get search data based on vinprefix and this search is based on like as we return data for browsing
		-- if no data is found on vinprefix search using vin
		--	
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'VinPrefix',
			VPRE.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			V.VehicleID,
			V.VIN,
			M.ModelDescription,
			R.RegistrationNumber,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + ']' + '[' + ISNULL(V.VIN, '') + ']' + '[' + M.ModelDescription + ']' + '[' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			''
		FROM Vehicle.Registrations R
				INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
				INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
				INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
				INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
				LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			WHERE 
				V.VIN LIKE @VinPrefix+'%'
				AND V.VINPrefix <> @VinPrefix
	END		
	--
	-- get search data based on chasis number and this search is based on like as we return data for browsing
	--	
	IF ( LEN(@ChassisNumber) > 0 )
	BEGIN
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'ChassisNumber',
			VPRE.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			V.VehicleID,
			V.VIN,
			M.ModelDescription,
			R.RegistrationNumber,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + ']' + '[' + ISNULL(V.VIN, '') + ']' + '[' + M.ModelDescription + ']' + '[' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			''
		FROM Vehicle.Registrations R
			INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
			INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
			INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
			INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
			LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
		WHERE 
			V.ChassisNumber = @ChassisNumber
			
		INSERT INTO #SEARCHDATA
		(
			SearchedON ,
			ParytID ,
			FullName ,
			CompanyName ,
			VehicleID ,
			VIN ,
			ModelDescription ,
			RegistrationNumber ,
			OtherDetails ,
			VehicleStatus 
		)
		SELECT DISTINCT
			'ChassisNumber',
			VPRE.PartyID,
			Party.udfGetFullName(T.Title, PP.FirstName, PP.Initials, PP.MiddleName, PP.LastName, PP.SecondLastName) AS FullName,
			ISNULL(O.OrganisationName, '') AS CompanyName,
			V.VehicleID,
			V.VIN,
			M.ModelDescription,
			R.RegistrationNumber,
			'['+CONVERT( NVARCHAR(50), V.VehicleID) + ']' + ' [' + ISNULL(V.VIN, '') + ']' + ' [' + M.ModelDescription + ']' + ' [' + ISNULL(R.RegistrationNumber, '')+']' AS OtherDetails,
			''
		FROM Vehicle.Registrations R
				INNER JOIN Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
				INNER JOIN Vehicle.Vehicles V ON VRE.VehicleID = V.VehicleID
				INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID
				INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID LEFT JOIN Party.People PP
				INNER JOIN Party.Titles T ON T.TitleID = PP.TitleID ON PP.PartyID = VPRE.PartyID
				LEFT JOIN Party.Organisations O ON O.PartyID = VPRE.PartyID
			WHERE 
				V.VIN LIKE '%'+@ChassisNumber
				AND V.ChassisNumber <> @ChassisNumber
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
	ON SD.ParytID = VPR.PartyID
	LEFT JOIN Meta.PartyBestPostalAddresses PBPA ON VPR.PartyID = PBPA.PartyID
	
	SELECT 
		SearchedON ,
		ParytID ,
		FullName ,
		CompanyName ,
		VehicleID ,
		VIN ,
		ModelDescription ,
		RegistrationNumber ,
		VehicleStatus ,
		OtherDetails,
		CASE VehicleStatus WHEN 'LIVE' THEN 'Mark Sold' ELSE 'SOLD' END AS ChangevehicleStatus
	FROM #SEARCHDATA 
	ORDER BY SearchedON
	
	SELECT @RowCount = @@ROWCOUNT
	DROP TABLE #SEARCHDATA
		
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

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

