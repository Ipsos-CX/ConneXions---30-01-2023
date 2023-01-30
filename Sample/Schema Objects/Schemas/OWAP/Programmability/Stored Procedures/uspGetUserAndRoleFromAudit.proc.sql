
CREATE  PROCEDURE [OWAP].uspGetUserAndRoleFromAudit
(
	@AuditID INT,
	@PartyID INT OUTPUT,
	@RoleTypeID INT OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)
AS
/*
Description
-----------
Return PartyID and RoleTypeID from AuditID

Version		Date		Aurthor			Why
------------------------------------------------------------------------------------------------------
1.0			18/02/2004	Mark Davidson	Created
1.1			18/06/2012	Pardip Mudhar	Modified for new OWAP
*/
	--
	-- Disable counts
	--
	SET NOCOUNT ON
	--
	-- Rollback on Error
	--
	SET XACT_ABORT ON
	--
	-- Get PartyRoleID
	--
	SELECT
		@PartyID = wsu.PartyID,
		@RoleTypeID = wsu.RoleTypeID
	FROM
		[Sample_Audit].[OWAP].Sessions AS wss
		JOIN [OWAP].[vwUsers] AS wsu
			ON wsu.PartyRoleID = wss.UserPartyRoleID
	WHERE
		wss.AuditID = @AuditID

	SELECT @ErrorCode = @@Error

/* ##### End of Procedure uspGetUserAndRoleFromAudit #### */
GO
