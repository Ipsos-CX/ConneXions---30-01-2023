CREATE TABLE [dbo].[MigrationErrorLog]
(
	ID INT IDENTITY(1,1) NOT NULL, 
	ErrorDateTime DATETIME2 NOT NULL,
	PackageName VARCHAR(100),
	TaskName VARCHAR(100),
	RowData NVARCHAR(2000),
	ErrorDescription NVARCHAR(500)
)
