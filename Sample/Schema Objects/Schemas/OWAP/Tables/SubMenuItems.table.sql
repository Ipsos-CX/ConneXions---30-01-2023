
CREATE TABLE [OWAP].[SubMenuItems](
	[MenuItemID] [dbo].[MenuItemID] NOT NULL,
	[SubmenuItemID] [dbo].[MenuItemID] IDENTITY(1,1) NOT NULL,
	[TargetURL] [varchar](510) NOT NULL,
	[ObjectName] [varchar](100) NOT NULL,
	[DisplayOrder] [tinyint] NOT NULL,
	[MenuEnabled] [BIT] NOT NULL
 ) ON [PRIMARY]
GO


