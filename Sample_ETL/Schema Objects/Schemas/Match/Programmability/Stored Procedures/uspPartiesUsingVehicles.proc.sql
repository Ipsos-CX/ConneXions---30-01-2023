CREATE PROCEDURE [Match].[uspPartiesUsingVehicles]

AS


/*
	Purpose:	Match PARENT VWT to Audit records based on a Checksum of Name details and VIN details
	
	Version			Date			Developer			Comment
	LIVE			1.0				$(ReleaseDate)		???					Created from [Prophet-ETL] proc
	LIVE			1.1				21/11/2013		Chris Ross			9678 - Add alternative matching for Non-UK Roadside 
															   where we use Lastname only (excluding Checksum) for matching parties.
	LIVE			1.2				29/04/2015		Chris Ross			6061 - CRC: Only do matching where not one of the dummy CRC vehicles.
	LIVE			1.3				11/08/2016		Chris Ross			12859 - Exclude Lost Leads from Vehicle Matching as it has dummy vehicles based on Model Description
	LIVE			1.4				19/01/2019		Chris Ross			12517 - Patch to populate VehicleIDs on CRM CRC dummy vehicle VINs
	LIVE			1.5				10/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	LIVE			1.6				01-06-2022		Ben King			TASK 880 - Land Rover Experience - Update Load from VWT package
*/


SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	------------------------------------------------------------------------------------------
	-- Get dummy CRC & LRE vehicles for reference purposes
	------------------------------------------------------------------------------------------

	DECLARE @JagCRCVehicleID  int,
			@LR_CRCVehicleID  int,
			@LR_EXPVehicleID  int
			

	SELECT @JagCRCVehicleID = VehicleID
	from [$(SampleDB)].Vehicle.Vehicles
	where VIN = 'SAJ_CRC_Unknown_V'
		
	SELECT @LR_CRCVehicleID = VehicleID 
	from [$(SampleDB)].Vehicle.Vehicles
	where VIN = 'SAL_CRC_Unknown_V'

	-- V1.6
	SELECT @LR_EXPVehicleID = VehicleID 
	from [$(SampleDB)].Vehicle.Vehicles
	WHERE VIN = 'SAL_LRE_Unknown_V'
	

	-- v1.4 - Addtional code TEMP FIX : CGR 19-01-2019 - Set the MatchedODSVehcileID for the CRC dummy vehicles so that the CRC bypass works correctly

	UPDATE v
	SET v.MatchedODSVehicleID = CASE WHEN VehicleIdentificationNumber = 'SAL_CRC_Unknown_V' 
									THEN @LR_CRCVehicleID
									ELSE @JagCRCVehicleID
									END
	FROM dbo.VWT v
	WHERE ISNULL(v.MatchedODSVehicleID, 0) = 0
	AND v.VehicleIdentificationNumber IN ('SAL_CRC_Unknown_V', 'SAJ_CRC_Unknown_V')


	-- V1.6
	UPDATE v
	SET v.MatchedODSVehicleID = @LR_EXPVehicleID
	FROM dbo.VWT v
	WHERE ISNULL(v.MatchedODSVehicleID, 0) = 0
	AND v.VehicleIdentificationNumber IN ('SAL_LRE_Unknown_V')


		

	-- EXACT MATCH PEOPLE USING VEHICLES  (NON-UK ROADSIDE ONLY)   -- v1.1
	--------------------------------------------------------------------------
	UPDATE V
	SET V.MatchedODSPersonID = AP.MatchedPersonID
	FROM dbo.vwVWT_People VP
	INNER JOIN Lookup.META_VehiclesAndPeople AP ON VP.VehicleChecksum = AP.VehicleChecksum
												AND VP.LastName = AP.LastName			-- CGR 03-04-13 To ensure better matching 
	INNER JOIN dbo.VWT V ON VP.AuditItemID = V.AuditItemID
	WHERE VP.MatchedODSPersonID = 0
	AND VP.VehicleIdentificationNumberUsable = 1 -- TRUSTED VIN
	AND (	VP.ODSEventTypeID = (select EventTypeID from [$(SampleDB)].event.EventTypes where EventType = 'Roadside')   
			AND VP.CountryID <> (select CountryID from [$(SampleDB)].ContactMechanism.Countries where Country = 'United Kingdom')
		)
	AND V.MatchedODSVehicleID NOT IN ( @JagCRCVehicleID, @LR_CRCVehicleID, @LR_EXPVehicleID)			-- v1.2, -- V1.6
	AND V.ODSEventTypeID <> (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')  -- v1.3 - No vehicle matching for Lost Leads

	-- EXACT MATCH PEOPLE USING VEHICLES (Everything else, excluding Non-UK Roadside) 
	-------------------------------------------------------------------------
	UPDATE V
	SET V.MatchedODSPersonID = AP.MatchedPersonID
	FROM dbo.vwVWT_People VP
	INNER JOIN Lookup.META_VehiclesAndPeople AP ON VP.NameChecksum = AP.NameChecksum
												AND VP.VehicleChecksum = AP.VehicleChecksum
												AND VP.LastName = AP.LastName			-- CGR 03-04-13 To ensure better matching 
	INNER JOIN dbo.VWT V ON VP.AuditItemID = V.AuditItemID
	WHERE VP.MatchedODSPersonID = 0
	AND VP.VehicleIdentificationNumberUsable = 1 -- TRUSTED VIN
	AND (	VP.ODSEventTypeID <> (select EventTypeID from [$(SampleDB)].event.EventTypes where EventType = 'Roadside')   
			OR VP.CountryID = (select CountryID from [$(SampleDB)].ContactMechanism.Countries where Country = 'United Kingdom')
		)
	AND V.MatchedODSVehicleID NOT IN ( @JagCRCVehicleID, @LR_CRCVehicleID, @LR_EXPVehicleID)			-- v1.2, -- V1.6
	AND V.ODSEventTypeID <> (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')  -- v1.3 - No vehicle matching for Lost Leads


	/* WE HAVE ONLY UPDATED ROW(S) THAT HAVE THE SAME VIN. THESE RECORDS MAY BE PART OF A SET THAT 
	   SHARE THE SAME FIRSTOWNER PARENT. UPDATE THE UNMATCHED SIBLINGS TO ENSURE THEY HAVE A MATCHED
	   PERSON ID PRIOR TO LOAD INTO THE SYSTEM */

	UPDATE VP
	SET VP.MatchedODSPersonID = VM.MatchedODSPersonID
	FROM dbo.vwVWT_People VP
	INNER JOIN dbo.vwVWT_People VM ON VP.PersonParentAudititemID =  VM.PersonParentAudititemID
	WHERE VP.MatchedODSPersonID = 0
	AND VM.MatchedODSPersonID > 0

	
	-- EXACT MATCH ORGANISATIONS USING VEHICLES
	UPDATE V
	SET V.MatchedODSOrganisationID = AO.MatchedOrganisationID
	FROM dbo.vwVWT_Organisations VO
	INNER JOIN Lookup.META_VehiclesAndOrganisations AO ON VO.OrganisationNameChecksum = AO.OrganisationNameChecksum
													AND VO.VehicleChecksum = AO.VehicleChecksum
	INNER JOIN dbo.VWT V ON VO.AuditItemID = V.AuditItemID
	WHERE VO.MatchedODSOrganisationID = 0
	AND VO.VehicleIdentificationNumberUsable = 1
	AND V.MatchedODSVehicleID NOT IN ( @JagCRCVehicleID, @LR_CRCVehicleID, @LR_EXPVehicleID)			-- v1.2, -- V1.6
	AND V.ODSEventTypeID <> (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')  -- v1.3 - No vehicle matching for Lost Leads


	/* 
		WE HAVE ONLY UPDATED ROW(S) THAT HAVE THE SAME VIN. THESE RECORDS MAY BE PART OF A SET THAT 
		SHARE THE SAME ORGANISATION PARENT. UPDATE THE UNMATCHED SIBLINGS TO ENSURE THEY HAVE A MATCHED
		ORGANISATION ID PRIOR TO LOAD INTO THE SYSTEM.
	*/

	UPDATE VO
	SET VO.MatchedODSOrganisationID = VM.MatchedODSOrganisationID
	FROM dbo.vwVWT_Organisations VO
	INNER JOIN dbo.vwVWT_Organisations VM ON VM.OrganisationParentAudititemID = VO.OrganisationParentAudititemID
	WHERE VO.MatchedODSOrganisationID = 0
	AND VM.MatchedODSOrganisationID > 0
	
	
	-- FUZZY MATCH ORGANISATIONS USING VEHICLES

	CREATE TABLE #OrganisationVehicleMatches
	(
		 AuditItemID BIGINT
		,MatchedOrganisationID INT
		,Rating INT
	)

	INSERT INTO #OrganisationVehicleMatches 
	(
		AuditItemID,
		MatchedOrganisationID,
		Rating
	)
	SELECT
		VO.AuditItemID,
		AO.MatchedOrganisationID,	
		dbo.udfFuzzyMatchWeighted(VO.OrganisationName, AO.OrganisationName) AS Rating
	FROM dbo.vwVWT_Organisations VO
	INNER JOIN Lookup.META_VehiclesAndOrganisations AO ON VO.VehicleChecksum = AO.VehicleChecksum
	INNER JOIN dbo.VWT V ON VO.AuditItemID = V.AuditItemID
	WHERE VO.MatchedODSOrganisationID = 0
	AND VO.VehicleIdentificationNumberUsable = 1
	AND VO.CountryID <> (SELECT DISTINCT CountryID FROM Lookup.vwCountries WHERE Country = 'Japan')	-- NO JAPANSE ORGANISATIONS
	AND V.MatchedODSVehicleID NOT IN ( @JagCRCVehicleID, @LR_CRCVehicleID, @LR_EXPVehicleID)			-- v1.2, -- V1.6
	AND V.ODSEventTypeID <> (SELECT EventTypeID FROM [$(SampleDB)].Event.EventTypes WHERE EventType = 'LostLeads')  -- v1.3 - No vehicle matching for Lost Leads


	-- UPDATE VWT WITH MAX FUZZY MATCH
	UPDATE V
	SET V.MatchedODSOrganisationID = OrganisationMatches.MatchedOrganisationID
	FROM VWT V
	INNER JOIN (
		SELECT DISTINCT 
			AuditItemID,
			MatchedOrganisationID,
			Rating
		FROM #OrganisationVehicleMatches VM1
		WHERE Rating = (
					SELECT MAX(Rating) 
					FROM #OrganisationVehicleMatches VM2
					WHERE VM2.AuditItemID = VM1.AuditItemID
					GROUP BY AuditItemID 
		)
		AND Rating > 50
	) OrganisationMatches ON V.AuditItemID = OrganisationMatches.AuditItemID


	DROP TABLE #OrganisationVehicleMatches



	/* 
		WE HAVE ONLY UPDATED ROW(S) THAT HAVE THE SAME VIN. THESE RECORDS MAY BE PART OF A SET THAT 
		SHARE THE SAME ORGANISATION PARENT. UPDATE THE UNMATCHED SIBLINGS TO ENSURE THEY HAVE A MATCHED
		ODS ORGANISATION ID PRIOR TO LOAD INTO ODS.
	*/

	UPDATE VO
	SET VO.MatchedODSOrganisationID = VM.MatchedODSOrganisationID
	FROM vwVWT_Organisations VO
	INNER JOIN (
		SELECT DISTINCT
			OrganisationParentAudititemID, 
			MatchedODSOrganisationID
		FROM vwVWT_Organisations
		WHERE MatchedODSOrganisationID > 0
	) VM ON VO.OrganisationParentAudititemID =  VM.OrganisationParentAudititemID
	WHERE VO.MatchedODSOrganisationID = 0


END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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