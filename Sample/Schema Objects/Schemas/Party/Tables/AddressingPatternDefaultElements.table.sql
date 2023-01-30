CREATE TABLE [Party].[AddressingPatternDefaultElements]
(
	AddressingTypeID dbo.AddressingTypeID NOT NULL,
	OrdinalPosition           TINYINT       NOT NULL,
    AddressElement            NVARCHAR (50) NULL,
    QuestionnaireRequirementID dbo.RequirementID NOT NULL,
    Required           BIT NOT NULL
)
