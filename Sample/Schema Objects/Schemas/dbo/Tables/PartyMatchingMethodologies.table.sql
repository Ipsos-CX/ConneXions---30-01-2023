CREATE TABLE [dbo].PartyMatchingMethodologies
(
	ID						INT NOT NULL IDENTITY(1,1), 
	PartyMatchingMethodology  VARCHAR(50) NOT NULL,
	CreatedDate				 DATETIME NOT NULL,
	Notes					  VARCHAR(1000) NULL			
)
