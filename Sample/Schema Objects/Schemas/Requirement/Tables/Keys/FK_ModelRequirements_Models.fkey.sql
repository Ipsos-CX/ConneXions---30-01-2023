ALTER TABLE [Requirement].[ModelRequirements]
	ADD CONSTRAINT [FK_ModelRequirements_Models] 
	FOREIGN KEY (ModelID)
	REFERENCES Vehicle.Models (ModelID)	

