CREATE TABLE [OWAP].[MenuItems] (
    [MenuItemID]   dbo.MenuItemID IDENTITY (1, 1) NOT NULL,
    [TargetURL]    VARCHAR (510) NOT NULL,
    [ObjectName]   VARCHAR (100) NOT NULL,
    [DisplayOrder] TINYINT       NOT NULL,
    [MenuEnabled]  BIT
);

