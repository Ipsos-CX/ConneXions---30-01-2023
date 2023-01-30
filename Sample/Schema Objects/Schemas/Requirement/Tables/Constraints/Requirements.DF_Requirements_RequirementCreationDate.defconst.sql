ALTER TABLE [Requirement].[Requirements]
   ADD CONSTRAINT [DF_Requirements_RequirementCreationDate] 
   DEFAULT GETDATE()
   FOR RequirementCreationDate


