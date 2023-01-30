CREATE TABLE [Party].[ContactPreferencesEventCategoryOverides]
(
	MarketID						INT					 NOT NULL,
	EventCategoryID					dbo.EventCategoryID  NOT NULL,
	EventCategoryPersistOveride		BIT NOT NULL
);

