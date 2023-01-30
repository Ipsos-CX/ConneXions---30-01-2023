CREATE TABLE [dbo].[__EFMigrationsHistory]
(
	 [MigrationId] nvarchar(150) NOT NULL, --BUG 15078
     [ProductVersion] nvarchar(32) NOT NULL,
     CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
)
