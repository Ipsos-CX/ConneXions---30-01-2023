CREATE TABLE [dbo].[FranchiseTypesOutletFunctions]
(
	FranchiseTypeID INT NOT NULL,
	OutletFunctionID dbo.RoleTypeID NOT NULL,
	OutletFunction NVARCHAR(100) NOT NULL, 
    QuestionnaireID INT NOT NULL
)
