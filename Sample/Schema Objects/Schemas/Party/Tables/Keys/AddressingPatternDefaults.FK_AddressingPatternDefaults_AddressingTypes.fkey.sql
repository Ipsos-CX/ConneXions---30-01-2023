ALTER TABLE [Party].[AddressingPatternDefaults]
	ADD CONSTRAINT [FK_AddressingPatternDefaults_AddressingTypes] 
	FOREIGN KEY (AddressingTypeID)
	REFERENCES Party.AddressingTypes (AddressingTypeID)	

