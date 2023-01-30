CREATE TRIGGER [Event].[TR_I_vwDA_NonSolicitations] ON [Event].[vwDA_NonSolicitations]
INSTEAD OF INSERT
AS SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @Max_NonSolicitationID INT

	-- POPULATE TEMP TABLE VARIABLE SO WE CAN ASSIGN NEW NonSolicitationIDs
	DECLARE @NewNonSolicitations TABLE
	(
		ID INT IDENTITY(1, 1) NOT NULL,
		NonSolicitationID INT NULL,
		NonSolicitationTextID TINYINT NOT NULL,
		PartyID BIGINT NOT NULL,
		RoleTypeID SMALLINT NULL,
		FromDate DATETIME2 NOT NULL,
		ThroughDate DATETIME2 NULL,
		Notes NVARCHAR(1000) NULL,
		EventID dbo.EventID NULL
	)

	INSERT INTO @NewNonSolicitations
	(
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes,
		EventID
	)
	SELECT DISTINCT
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes,
		EventID
	FROM INSERTED

	-- GET CURRENT MAX ID FROM NonSolicitations SO WE CAN ASSIGN VALID ID'S TO NEW DATA.
	SELECT @Max_NonSolicitationID = ISNULL(MAX(NonSolicitationID), 0) FROM dbo.NonSolicitations

	UPDATE @NewNonSolicitations SET	NonSolicitationID = ID + @Max_NonSolicitationID

	INSERT INTO dbo.NonSolicitations
	(
		NonSolicitationID, 
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes
	)
	SELECT
		NonSolicitationID, 
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes
	FROM @NewNonSolicitations

	INSERT INTO Event.NonSolicitations
	(
		NonSolicitationID,
		EventID
	)
	SELECT NonSolicitationID, EventID
	FROM @NewNonSolicitations

	INSERT INTO [$(AuditDB)].Audit.NonSolicitations
	(
		AuditItemID, 
		NonSolicitationID, 
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes
	)
	SELECT
		I.AuditItemID, 
		NNS.NonSolicitationID, 
		NNS.NonSolicitationTextID,
		NNS.PartyID,
		NNS.RoleTypeID,
		NNS.FromDate,
		NNS.ThroughDate,
		NNS.Notes
	FROM @NewNonSolicitations NNS
	INNER JOIN INSERTED I ON I.NonSolicitationTextID = NNS.NonSolicitationTextID
						AND NNS.PartyID = I.PartyID
						AND NNS.FromDate = I.FromDate
						AND NNS.EventID = I.EventID


	INSERT INTO [$(AuditDB)].Audit.EventNonSolicitations
	(
		AuditItemID, 
		NonSolicitationID,
		EventID
	)
	SELECT
		I.AuditItemID, 
		NNS.NonSolicitationID,
		NNS.EventID
	FROM @NewNonSolicitations NNS
	INNER JOIN INSERTED I ON I.NonSolicitationTextID = NNS.NonSolicitationTextID
	AND NNS.PartyID = I.PartyID
	AND NNS.FromDate = I.FromDate

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

