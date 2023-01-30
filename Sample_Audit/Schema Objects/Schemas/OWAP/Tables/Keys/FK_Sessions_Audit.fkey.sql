ALTER TABLE [OWAP].[Sessions]
	ADD CONSTRAINT [FK_Sessions_Audit] 
	FOREIGN KEY (AuditID)
	REFERENCES dbo.Audit (AuditID)	

