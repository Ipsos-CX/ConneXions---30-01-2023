


CREATE  VIEW [OWAP].[vwMenuItemRoles]
AS
	SELECT
		MIR.RoleTypeID, 
		MI.MenuItemID, 
		MI.TargetURL, 
		MI.ObjectName, 	
		MI.DisplayOrder
	FROM
		OWAP.MenuItemRoles AS MIR
		JOIN 
			OWAP.MenuItems AS MI
			ON MIR.MenuItemID = MI.MenuItemID
	WHERE 
		MI.MenuEnabled = 1