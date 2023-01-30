ALTER TABLE [OWAP].[Programmes]
	ADD CONSTRAINT [FK_Programmes_Requirements] 
	FOREIGN KEY (ProgrammeRequirementID)
	REFERENCES Requirement.Requirements (RequirementID)

