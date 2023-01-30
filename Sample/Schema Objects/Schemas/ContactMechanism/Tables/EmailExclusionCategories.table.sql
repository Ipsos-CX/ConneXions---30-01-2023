CREATE TABLE ContactMechanism.EmailExclusionCategories (
    EmailExclusionCategoryID		dbo.ExclusionCategoryID  IDENTITY (1, 1) NOT NULL,
	ExclusionCategoryName			dbo.ExclusionCategoryName	NOT NULL,
	ExclusionCategoryDesc			dbo.ExclusionCategoryDesc	NOT NULL,
	IncludeInEmailCapture			dbo.IncludeInEmailCapture	NOT NULL DEFAULT (1)
);

