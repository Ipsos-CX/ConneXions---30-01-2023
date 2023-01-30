ALTER TABLE dbo.Markets
	ADD CONSTRAINT DF_Markets_ExcludeEmployeeData
	DEFAULT 0
	FOR ExcludeEmployeeData