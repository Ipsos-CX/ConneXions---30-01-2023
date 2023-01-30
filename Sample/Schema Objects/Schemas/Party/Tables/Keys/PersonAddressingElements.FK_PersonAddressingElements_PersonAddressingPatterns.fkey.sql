ALTER TABLE [Party].[PersonAddressingElements]
	ADD CONSTRAINT [FK_PersonAddressingElements_PersonAddressingPatterns] 
	FOREIGN KEY (PersonAddressingPatternID)
	REFERENCES Party.PersonAddressingPatterns (PersonAddressingPatternID)	

