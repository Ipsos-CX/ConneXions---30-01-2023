CREATE TABLE [Party].[ContactPreferencesOverride]
(
	[PartyId] [int] NULL,
	[BugNumber] [varchar](20) NULL,
	[Comments] [varchar](100) NULL,
	[EventCategory] [varchar](20) NULL,
	[MarketCountryID] [int] NOT NULL,
	[PartySuppression] [bit] NULL,
	[PostalSuppression] [bit] NULL,
	[EmailSuppression] [bit] NULL,
	[PhoneSuppression] [bit] NULL,
	[Date] [datetime] NULL
		CONSTRAINT DFT_ContactPreferencesOverride_Date DEFAULT GETDATE(),
	[Username] [nvarchar](50) NULL,
	[ProcessDate] [datetime] NULL,
	[EventCategoryID] [int] NULL
)
