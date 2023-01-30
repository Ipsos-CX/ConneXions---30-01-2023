CREATE PROC Migration.uspOWAP
AS

-- ADD THE NEW OWAP ROLE TYPES
--INSERT INTO dbo.RoleTypes (RoleType)
--VALUES ('OWAP Admin'), ('OWAP User')

-- ADD THEM ROLE TYPES TO THE OWAP.RoleTypes TABLE
INSERT INTO OWAP.RoleTypes (RoleTypeID)
SELECT RoleTypeID
FROM dbo.RoleTypes
WHERE RoleType IN ('OWAP Admin', 'OWAP User')


-- ADD THE MENU ITEMS
INSERT INTO OWAP.MenuItems (TargetURL, ObjectName, DisplayOrder)
VALUES ('Selection Review', 'Selection Review', 1),
('Customer Update', 'Customer Update', 2)


-- ADD THE MENU ITEM ROLES

-- Selection Review
INSERT INTO OWAP.MenuItemRoles (MenuItemID, RoleTypeID)
SELECT
	(SELECT MenuItemID FROM OWAP.MenuItems WHERE ObjectName = 'Selection Review') AS MenuItemID,
	(SELECT RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'OWAP Admin') AS RoleTypeID
UNION
SELECT
	(SELECT MenuItemID FROM OWAP.MenuItems WHERE ObjectName = 'Customer Update') AS MenuItemID,
	(SELECT RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'OWAP Admin') AS RoleTypeID
UNION
SELECT
	(SELECT MenuItemID FROM OWAP.MenuItems WHERE ObjectName = 'Selection Review') AS MenuItemID,
	(SELECT RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'OWAP User') AS RoleTypeID
UNION
SELECT
	(SELECT MenuItemID FROM OWAP.MenuItems WHERE ObjectName = 'Customer Update') AS MenuItemID,
	(SELECT RoleTypeID FROM dbo.RoleTypes WHERE RoleType = 'OWAP User') AS RoleTypeID

