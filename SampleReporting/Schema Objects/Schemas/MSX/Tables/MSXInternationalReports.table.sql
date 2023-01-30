CREATE TABLE [MSX].[MSXInternationalReports]
(
	ID INT IDENTITY(1,1), 
	FileName VARCHAR(100) NOT NULL,
	FileDate DATETIME2(7) NOT NULL,
	SequenceNumber INT NOT NULL
)
