CREATE PROCEDURE [OWAP].[uspGetAuditID]
(
	@SessionID NVARCHAR(100),
	@AuditID INT = 0 OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)
AS
/*
Description
-----------
Add WebSiteTransaction Audit

Version		Date		Aurthor		Why
------------------------------------------------------------------------------------------------------
1.0		04/12/2003	Mark Davidson	Created
1.1		18/06/2012	Pardip Mudhar	Migraded for New OWAP

*/
--Disable counts
	SET NOCOUNT ON

--Rollback on Error
	SET XACT_ABORT ON

--Get AuditID
	SELECT
		@AuditID = wss.AuditID
	FROM
		[Sample_Audit].OWAP.Sessions AS wss
	WHERE
		wss.SessionID = @SessionID

	SELECT @ErrorCode = @@Error

/* ##### End of Procedure uspAUDIT_GetAuditID #### */
