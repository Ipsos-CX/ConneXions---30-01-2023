
CREATE PROCEDURE [OWAP].[uspAddUserToRole]
(
	@AuditItemID BIGINT,
	@UserID INT,
	@UserRoleTypeID SMALLINT,
	@UserName NVARCHAR(50),
	@Password NVARCHAR(255),
	@ErrorCode INT OUTPUT
)
AS

/*
Description
-----------

Version		Date		Aurthor			Why
------------------------------------------------------------------------------------------------------
1.0			26/11/2003	Mark Davidson	Created
1.1			18/06/2012	Pardip Mudhar	Migrated for new OWAP
*/

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)
	
	SET @ErrorCode = 0
	
	--
	-- Disable Counts
	SET NOCOUNT ON
	--
	-- Rollback on error
	--
	SET XACT_ABORT ON
	--
	--Add Role
	--
	BEGIN TRY
		INSERT INTO
			[OWAP].[vwUsers]
			(
				PartyID,
				RoleTypeID,
				PartyRoleID,
				UserName,
				[Password]
			)
		VALUES
		(
			@UserID,
			@UserRoleTypeID,
			0,
			@UserName,
			@Password
		)
	--
	-- Return Error code
	--
	SET @ErrorCode = 0
	END TRY
	BEGIN CATCH
		IF ( @@TRANCOUNT > 0 )
		BEGIN
			ROLLBACK
		END
		
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
/* ##### End of Procedure uspUSERS_AddUserToRole #### */
