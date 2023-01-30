CREATE TRIGGER Party.TR_I_vwDA_NonSolicitations ON Party.vwDA_NonSolicitations
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads party non solications data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_PartyNonSolicitations.TR_I_vwDA_PartyNonSolicitations

*/

SET NOCOUNT ON

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
		HardSet    INT NULL
	)

	INSERT INTO @NewNonSolicitations
	(
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes,
		HardSet
	)
	SELECT DISTINCT
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes,
		ISNULL(HardSet, 0) AS HardSet
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
		Notes,
		Hardset
	)
	SELECT
		NonSolicitationID, 
		NonSolicitationTextID,
		PartyID,
		RoleTypeID,
		FromDate,
		ThroughDate,
		Notes,
		Hardset
	FROM @NewNonSolicitations

	INSERT INTO Party.NonSolicitations
	(
		NonSolicitationID
	)
	SELECT NonSolicitationID
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
		Notes,
		Hardset
	)
	SELECT
		I.AuditItemID, 
		NNS.NonSolicitationID, 
		NNS.NonSolicitationTextID,
		NNS.PartyID,
		NNS.RoleTypeID,
		NNS.FromDate,
		NNS.ThroughDate,
		NNS.Notes,
		NNS.Hardset
	FROM @NewNonSolicitations NNS
	INNER JOIN INSERTED I ON I.NonSolicitationTextID = NNS.NonSolicitationTextID
						AND NNS.PartyID = I.PartyID
						AND NNS.FromDate = I.FromDate


	INSERT INTO [$(AuditDB)].Audit.PartyNonSolicitations
	(
		AuditItemID, 
		NonSolicitationID
	)
	SELECT
		I.AuditItemID, 
		NNS.NonSolicitationID
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