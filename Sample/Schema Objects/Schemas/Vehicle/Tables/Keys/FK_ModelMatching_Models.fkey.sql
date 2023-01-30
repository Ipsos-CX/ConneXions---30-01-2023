ALTER TABLE [Vehicle].[ModelMatching]
	ADD CONSTRAINT [FK_ModelMatching_Models] 
	FOREIGN KEY (ModelID)
	REFERENCES Vehicle.Models (ModelID)	

