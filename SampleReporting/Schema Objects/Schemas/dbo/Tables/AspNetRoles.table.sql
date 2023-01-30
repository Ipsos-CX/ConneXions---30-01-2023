CREATE TABLE [dbo].[AspNetRoles]
(
	[Id] nvarchar(450) NOT NULL, --BUG 15078
    [Name] nvarchar(256) NULL,
    [NormalizedName] nvarchar(256) NULL,
    [ConcurrencyStamp] nvarchar(max) NULL,
    CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
)
