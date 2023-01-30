CREATE TRIGGER Party.TR_I_vwDA_Parties ON Party.vwDA_Parties
INSTEAD OF INSERT

AS

/*
	Purpose:	Handles insert into vwDA_Parties
				All rows in VWT lacking organisation / person information should be inserted into view.
				All rows are written to the Audit.Parties table
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_Parties.TR_I_vwDA_Parties

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

		-- CREATE VARIABLE TO HOLD THE MAXIMUM PARTYID
		DECLARE @Max_PartyID INT

		-- CREATE A TABLE TO STORE THE NEW PEOPLE DATA
		DECLARE @Parties TABLE
		(
			ID INT IDENTITY(1, 1) NOT NULL, 
			AuditItemID BIGINT NOT NULL, 
			PartyID INT,
			RoleTypeID SMALLINT,
			UNIQUE(AuditItemID),
			UNIQUE(PartyID, ID)
		)

		-- GET THE NEW (UNMATCHED) UNIQUE PEOPLE DATA
		INSERT INTO @Parties
		(
			AuditItemID,
			RoleTypeID
		)
		SELECT 
			AuditItemID,
			RoleTypeID
		FROM INSERTED
		WHERE PartyID = 0


		-- GET THE MAXIMUM PARTYID
		SELECT @Max_PartyID = ISNULL(MAX(PartyID), 0) FROM Party.Parties

		-- GENERATE THE NEW PARTYIDS USING THE IDENTITY VALUE
		UPDATE @Parties
		SET PartyID = ID + @Max_PartyID

		-- ADD THE NEW PARTIES TO THE PARTIES TABLE
		INSERT INTO Party.Parties
		(
			PartyID
		)
		SELECT DISTINCT 
			PartyID
		FROM @Parties
		ORDER BY PartyID
		
		-- UPDATE VWT WITH PARTYIDS OF INSERTED PARTIES
		UPDATE V
		SET V.MatchedODSPartyID = P.PartyID
		FROM [$(ETLDB)].dbo.VWT V
		INNER JOIN @Parties P ON P.AuditItemID = V.AuditItemID

		-- INSERT ALL THE PEOPLE INTO Audit.Parties WHERE WE'VE NOT ALREADY LOADED THEM
		INSERT INTO [$(AuditDB)].Audit.Parties
		(
			AuditItemID, 		
			PartyID, 
			FromDate
		)
		SELECT DISTINCT
			I.AuditItemID, 
			P.PartyID, 
			I.FromDate
		FROM INSERTED I
		LEFT JOIN @Parties P ON P.AuditItemID = I.AuditItemID		
		LEFT JOIN [$(AuditDB)].Audit.Parties AP ON AP.PartyID = P.PartyID
											AND AP.AuditItemID = I.AuditItemID
		WHERE AP.AuditItemID IS NULL
		ORDER BY I.AuditItemID

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