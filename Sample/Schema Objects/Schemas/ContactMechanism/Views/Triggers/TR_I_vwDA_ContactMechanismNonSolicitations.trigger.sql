CREATE TRIGGER ContactMechanism.TR_I_vwDA_ContactMechanismNonSolicitations ON ContactMechanism.vwDA_ContactMechanismNonSolicitations
INSTEAD OF INSERT

AS

/*
	Purpose:	Adds a new contact mechanism non solication and audits it
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_vwDA_ContactMechanismNonSolicitations.TR_I_vwDA_ContactMechanismNonSolicitations
	1.1				11-02-2015		Chris Ross			BUG 10671 - Add in HardSet flag 
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- POPULATE TEMP TABLE VARIABLE SO WE CAN ASSIGN NEW NonSolicitationIDs
		CREATE TABLE #NonSolicitations
		(
			ID INT IDENTITY(1, 1) NOT NULL,
			NonSolicitationID INT NULL,
			AuditItemID BIGINT NOT NULL,
			NonSolicitationTextID SMALLINT NOT NULL,
			PartyID INT NOT NULL,
			RoleTypeID SMALLINT NULL,
			FromDate DATETIME2 NOT NULL,
			ThroughDate DATETIME2 NULL,
			Notes NVARCHAR(1000) NULL,
			ContactMechanismID INT NOT NULL,
			HardSet				INT NOT NULL
		)

		INSERT INTO #NonSolicitations
		(
			AuditItemID,
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			ContactMechanismID,
			HardSet
		)
		SELECT
			AuditItemID,
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			ContactMechanismID,
			ISNULL(HardSet, 0) AS HardSet
		FROM INSERTED

		-- GET CURRENT MAX ID FROM NonSolicitations SO WE CAN ASSIGN VALID ID'S TO NEW DATA.
		DECLARE @MaxID INT
		SELECT @MaxID = MAX(NonSolicitationID) FROM dbo.NonSolicitations

		UPDATE #NonSolicitations
		SET	NonSolicitationID = ID + @MaxID

		-- INSERT INTO NonSolicitations
		INSERT INTO dbo.NonSolicitations
		(
			NonSolicitationID, 
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			HardSet
		)
		SELECT
			NonSolicitationID, 
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			HardSet
		FROM #NonSolicitations

		--INSERT INTO ContactMechanismNonSolicitations
		INSERT INTO ContactMechanism.NonSolicitations
		(
			NonSolicitationID, 
			ContactMechanismID
		)
		SELECT
			NonSolicitationID, 
			ContactMechanismID
		FROM #NonSolicitations

		-- INSERT INTO Audit NonSolicitations
		INSERT INTO [$(AuditDB)].Audit.NonSolicitations
		(
			AuditItemID, 
			NonSolicitationID, 
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			HardSet
		)
		SELECT
			AuditItemID, 
			NonSolicitationID, 
			NonSolicitationTextID,
			PartyID,
			RoleTypeID,
			FromDate,
			ThroughDate,
			Notes,
			HardSet
		FROM #NonSolicitations

		-- INSERT INTO Audit ContactMechanismNonSolicitations
		INSERT INTO [$(AuditDB)].Audit.ContactMechanismNonSolicitations
		(
			AuditItemID, 
			NonSolicitationID, 
			ContactMechanismID
		)
		SELECT
			AuditItemID, 
			NonSolicitationID, 
			ContactMechanismID
		FROM #NonSolicitations
		

	COMMIT TRAN

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