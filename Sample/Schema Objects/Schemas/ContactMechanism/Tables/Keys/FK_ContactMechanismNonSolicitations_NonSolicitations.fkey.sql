ALTER TABLE [ContactMechanism].[NonSolicitations]
	ADD CONSTRAINT [FK_ContactMechanismNonSolicitations_NonSolicitations] 
	FOREIGN KEY (NonSolicitationID)
	REFERENCES dbo.NonSolicitations (NonSolicitationID)	

