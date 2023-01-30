

CREATE   PROCEDURE [OWAP].[uspGetMenuItems]
(
	@RoleTypeID DBO.RoleTypeID,
	@RowCount INT = 0 OUTPUT,
	@ErrorCode INT = 0 OUTPUT 
)
AS
BEGIN
/*
Description
-----------

Version		Date		Aurthor			Why
------------------------------------------------------------------------------------------------------
1.0			08-May-2012	Pardip Mudhar	Created

*/
--Disable Counts
	SET NOCOUNT ON

--Rollback on error
	SET XACT_ABORT ON	

--Return MenuItems result set
	SELECT 
		MI.MenuItemID,
		MenuDisplayOrder,
		MenuTargetURL,
		MenuObjectName,
		SubMenuItemID,
		SubTargetURL,
		SubObjectName,
		SubDisplayOrder,
		RoleTypeID
	FROM 
		[Sample].OWAP.vwMenuItems MI
	WHERE
		MI.RoleTypeID = @RoleTypeID
	ORDER BY
		MI.RoleTypeID,
		MI.MenuDisplayOrder,
		MI.SubDisplayOrder
	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END 
