ALTER TABLE [ContactMechanism].[NonSolicitations]
	ADD CONSTRAINT [FK_ContactMechanismNonSolicitations_ContactMechanisms] 
	FOREIGN KEY (ContactMechanismID)
	REFERENCES ContactMechanism.ContactMechanisms (ContactMechanismID)	

