CREATE TABLE [Event].[EventCategories]
(
	EventCategoryID dbo.EventCategoryID IDENTITY(1,1) NOT NULL, 
	EventCategory						VARCHAR(50) NOT NULL,
	IncludeInLatestEmailMetadata		INT NULL
)
	