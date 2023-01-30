CREATE TABLE [dbo].[SampleLoadErrorLog]
(
	ID INT IDENTITY(1,1) NOT NULL, 
	ErrorDateTime DATETIME2 NOT NULL,
	PackageName VARCHAR(100),
	AuditID BIGINT,
	FileName VARCHAR(500),
	RowNumber INT,
	ErrorColumn INT,
	ErrorDescription NVARCHAR(500)
)
