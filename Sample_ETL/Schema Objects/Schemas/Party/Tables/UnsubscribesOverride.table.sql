CREATE TABLE [Party].[UnsubscribesOverride](
	[PartyId] [int] NULL,
	[BugNumber] [varchar](20) NULL,
	[Comments] [varchar](100) NULL,
	[EventCategory] [varchar](20) NULL,
	[MarketCountryID] [int] NOT NULL,
	[RemoveUnsubscribe] [bit] NULL,
	[Date] [datetime] NULL
		CONSTRAINT DFT_UnsubscribesOverride_Date DEFAULT GETDATE(),
	[Username] [nvarchar](50) NULL,
	[ProcessDate] [datetime] NULL,
	[EventCategoryID] [int] NULL
) 
