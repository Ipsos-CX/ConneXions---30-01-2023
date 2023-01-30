CREATE PROCEDURE [dbo].[uspPopulateVehicleWarrantyClaimCount]

AS

/*

	Purpose:	Create daily table of Warranty claims per dealer with >1 claim in last 6 months

	Version		Developer		Date		Comment
	1.0			Attila Kubanda	03/10/2011	Created

*/

/*
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		DELETE FROM dbo.VehicleWarrantyClaimCount

		INSERT INTO dbo.VehicleWarrantyClaimCount
		(
			VehicleID,
			CurrentOwner
		)
		SELECT
			VPRE.VehicleID, 
			MAX(RO.PartyID) AS CurrentOwner
		FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
		INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoles VPR ON VPR.PartyID = VPRE.PartyID 
															AND VPR.VehicleRoleTypeID = VPRE.VehicleRoleTypeID 
															AND VPR.VehicleID = VPRE.VehicleID 
															AND COALESCE(VPR.ThroughDate, '31 December 9999') > CURRENT_TIMESTAMP
		INNER JOIN (
			SELECT DISTINCT
				PartyID, 
				VehicleID,
				VehicleRoleTypeID
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents
			WHERE VehicleRoleTypeID = (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
		) RO ON RO.VehicleID = VPRE.VehicleID 
			AND RO.VehicleRoleTypeID = VPRE.VehicleRoleTypeID	
		GROUP BY VPRE.VehicleID


		-- ADD THE VEHICLE INFORMATION
		UPDATE VWCC
		SET VWCC.VIN = V.VIN, VWCC.ReportingModel = M.ModelDescription
		FROM [$(SampleDB)].Vehicle.Vehicles V
		INNER JOIN dbo.VehicleWarrantyClaimCount VWCC ON VWCC.VehicleID = V.VehicleID
		INNER JOIN [$(SampleDB)].Vehicle.Models M ON M.ModelID = V.ModelID


		-- ADD THE SALES DATE
		UPDATE VWCC
		SET VWCC.SalesDate = COALESCE(S.EventDate, R.RegistrationDate)
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN (
			SELECT DISTINCT
				VPRES.VehicleID,
				MIN(E.EventDate) AS EventDate
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRES
			INNER JOIN [$(SampleDB)].Event.Events E ON VPRES.EventID = E.EventID
			INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			WHERE ET.EventCategory = 'Sales'
			GROUP BY VPRES.VehicleID
		) S ON S.VehicleID = VWCC.VehicleID
		LEFT JOIN (
			SELECT DISTINCT
				VRE.VehicleID,
				MAX(R.RegistrationDate) AS RegistrationDate
			FROM [$(SampleDB)].Vehicle.Registrations R
			INNER JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE ON VRE.RegistrationID = R.RegistrationID
			GROUP BY VRE.VehicleID
		) R ON R.VehicleID = VWCC.VehicleID




		-- ADD THE NUMBER FOR WARRNTY VISITS FOR THE VEHICLE
		UPDATE VWCC
		SET VWCC.TotalVisits = WC.TotalVisits
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN (
			SELECT VPRE.VehicleID, COUNT(DISTINCT E.EventDate) AS TotalVisits
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
			INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
			INNER JOIN [$(SampleDB)].Event.Events E ON E.EventID = VPRE.EventID
			INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			WHERE ET.EventType = 'Warranty'
			AND VRT.VehicleRoleType = 'Principle Driver'
			GROUP BY VPRE.VehicleID
		) WC ON WC.VehicleID = VWCC.VehicleID



		-- DELETE ANY ROWS THAT HAVE NOT HAD A WARRANTY VISIT
		DELETE	
		FROM dbo.VehicleWarrantyClaimCount
		WHERE ISNULL(TotalVisits, 0) = 0



		-- GET THE DealerPartyID WHERE THE LAST WARRANTY VISIT OCCURRED
		UPDATE VWCC
		SET	LastWarrantyVisit = D.LastWarrantyVisit
			,DealerPartyID = D.DealerPartyID
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN (
			SELECT DISTINCT
				 VPRE.VehicleID
				,EPR.PartyID AS DealerPartyID
				,MAX(E.EventDate) AS LastWarrantyVisit
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
			INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
			INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
			INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
			WHERE ET.EventType = 'Warranty'
			AND	VRT.VehicleRoleType = 'Principle Driver'
			AND	ISNULL(EPR.PartyID, 0) <> 0
			GROUP BY VPRE.VehicleID, EPR.PartyID
		) D ON D.VehicleID = VWCC.VehicleID
		
		
		-- DELETE ANY ROWS WHERE WE HAVEN'T GOT A DEALER
		DELETE	
		FROM dbo.VehicleWarrantyClaimCount
		WHERE ISNULL(DealerPartyID, 0) = 0



		-- GET COUNTS OF WARRANTY VISITS TO THE LATEST DEALER IN THE LAST SIX MONTHS
		UPDATE VWCC
		SET VWCC.DealerVisitsLastSixMonths = SM.DealerVisitsLastSixMonths
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN (
			SELECT DISTINCT
				VPRE.VehicleID,
				EPR.PartyID AS DealerPartyID,
				COUNT(DISTINCT E.EventDate) AS DealerVisitsLastSixMonths
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
			INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
			INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
			INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
			WHERE ET.EventType = 'Warranty'
			AND	VRT.VehicleRoleType = 'Principle Driver'
			AND	E.EventDate >= DATEADD(D, -180, GETDATE())
			GROUP BY VPRE.VehicleID, EPR.PartyID
		) SM ON SM.VehicleID = VWCC.VehicleID AND SM.DealerPartyID = VWCC.DealerPartyID


		-- GET COUNTS OF WARRANTY VISITS TO ALL DEALERS IN THE LAST SIX MONTHS
		UPDATE VWCC
		SET VWCC.AllVisitsLastSixMonths = SM.AllVisitsLastSixMonths
		FROM dbo.VehicleWarrantyClaimCount VWCC
		INNER JOIN (
			SELECT DISTINCT
				VPRE.VehicleID,
				COUNT(DISTINCT E.EventDate) AS AllVisitsLastSixMonths
			FROM [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE
			INNER JOIN [$(SampleDB)].Vehicle.VehicleRoleTypes VRT ON VRT.VehicleRoleTypeID = VPRE.VehicleRoleTypeID
			INNER JOIN [$(SampleDB)].Event.Events E ON VPRE.EventID = E.EventID
			INNER JOIN [$(SampleDB)].Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
			WHERE ET.EventType = 'Warranty'
			AND	VRT.VehicleRoleType = 'Principle Driver'
			AND	E.EventDate >= DATEADD(D, -180, GETDATE())
			GROUP BY VPRE.VehicleID
		) SM ON SM.VehicleID = VWCC.VehicleID



		-- GET THE CUSTOMER NAME
		UPDATE VWCC
		SET VWCC.CustomerName = RTRIM(LTRIM(CASE 
									WHEN P.PartyID IS NOT NULL 
										THEN 
											REPLACE(
											REPLACE(
											REPLACE(
											REPLACE(
												LTRIM(RTRIM(P.LastName)) + '|' +
												LTRIM(RTRIM(P.SecondLastName)) + '|,' +
												LTRIM(RTRIM(T.Title)) + '|' + 
												LTRIM(RTRIM(P.FirstName))
											,'|,', ', ')
											,'||', ' ')
											,'|', ' ')
											,' ,', ',')
									WHEN O.PartyID IS NOT NULL
										THEN O.OrganisationName
									END))
		FROM dbo.VehicleWarrantyClaimCount VWCC
		LEFT JOIN [$(SampleDB)].[Party].People P
			INNER JOIN [$(SampleDB)].[Party].Titles T ON P.TitleID = T.TitleID
		ON VWCC.CurrentOwner = P.PartyID
		LEFT JOIN [$(SampleDB)].[Party].Organisations O ON VWCC.CurrentOwner = O.PartyID
		WHERE VWCC.CurrentOwner IS NOT NULL

	COMMIT TRAN

END TRY
BEGIN CATCH

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
*/