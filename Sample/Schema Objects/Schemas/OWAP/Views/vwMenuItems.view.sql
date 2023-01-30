

CREATE  VIEW [OWAP].[vwMenuItems]
AS
/*
	Purpose:	Return dataset for menu items based on MenuItems, SubMenuItems, MenuItemRoles
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Pardip Mudhar		Created


*/
	SELECT 
		MI.MenuItemID AS MenuItemID,
		MI.DisplayOrder AS MenuDisplayOrder,
		MI.TargetURL AS MenuTargetURL,
		MI.ObjectName AS MenuObjectName,
		MI.MenuEnabled AS MenuEnabled,
		SMI.SubmenuItemID AS SubMenuItemID,
		SMI.TargetURL AS SubTargetURL,
		SMI.ObjectName AS SubObjectName,
		SMI.DisplayOrder AS SubDisplayOrder,
		SMI.MenuEnabled AS SubMenuEnabled,
		MIR.RoleTypeID AS RoleTypeID
	FROM 
		OWAP.MenuItems MI
			join OWAP.SubMenuItems SMI 
				ON	SMI.MenuItemID = MI.MenuItemID 
			JOIN OWAP.MenuItemRoles MIR 
				ON MIR.MenuItemID = MI.MenuItemID
		
GO

