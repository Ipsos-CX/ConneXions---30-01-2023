CREATE TRIGGER Event.TR_I_vwDA_AutomotiveEventBasedInterviews ON Event.vwDA_AutomotiveEventBasedInterviews
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads selected events into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_Case_AutomotiveEventBasedInterviews.TR_I_vwDA_Case_AutomotiveEventBasedInterviews

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- CREATE A TABLE TO HOLD THE SELECTED EVENTS (NEW CASES)
	DECLARE @NewCases TABLE
	(
		ID INT IDENTITY(1, 1),
		CaseStatusTypeID TINYINT,
		CaseID INT,
		EventID BIGINT, 
		PartyID INT, 
		VehicleRoleTypeID SMALLINT, 
		VehicleID BIGINT,
		SelectionRequirementID INT, 
		ModelRequirementID INT
	)

	-- GET THE NEW CASES
	INSERT INTO @NewCases
	(
		CaseStatusTypeID,
		EventID,
		PartyID,
		VehicleRoleTypeID,
		VehicleID,
		SelectionRequirementID,
		ModelRequirementID
	)
	SELECT
		CaseStatusTypeID,
		EventID,
		PartyID,
		VehicleRoleTypeID,
		VehicleID,
		SelectionRequirementID,
		ModelRequirementID
	FROM INSERTED
	
	-- GENERATE THE NEW CASEIDS
	DECLARE @MaxCaseID INT
	SELECT @MaxCaseID = ISNULL(MAX(CaseID), 0) FROM Event.Cases

	UPDATE @NewCases
	SET CaseID = ID + @MaxCaseID
	
	-- INSERT THE NEW CASES
	INSERT INTO Event.Cases (CaseID, CaseStatusTypeID)
	SELECT CaseID, CaseStatusTypeID
	FROM @NewCases

	INSERT INTO Event.AutomotiveEventBasedInterviews (CaseID, EventID, PartyID, VehicleRoleTypeID, VehicleID)
	SELECT CaseID, EventID, PartyID, VehicleRoleTypeID, VehicleID
	FROM @NewCases

	INSERT INTO Requirement.SelectionCases (CaseID, RequirementIDMadeUpOf, RequirementIDPartOf)
	SELECT CaseID, ModelRequirementID, SelectionRequirementID
	FROM @NewCases

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