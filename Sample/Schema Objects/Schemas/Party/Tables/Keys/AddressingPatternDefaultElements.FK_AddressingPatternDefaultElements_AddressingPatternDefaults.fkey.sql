ALTER TABLE [Party].[AddressingPatternDefaultElements]
	ADD CONSTRAINT [FK_AddressingPatternDefaultElements_AddressingPatternDefaults] 
	FOREIGN KEY (AddressingTypeID)
	REFERENCES Party.AddressingPatternDefaults (AddressingTypeID)	

