CREATE TABLE [CustomerUpdateFeeds].[EmailMarkets] (
		Market			VARCHAR(100) NOT NULL,
		DealerCode		VARCHAR(100) NOT NULL,
		EmailRecipients	VARCHAR(1000),
		EmailCC			VARCHAR(1000),
		EmailNonProd	VARCHAR(1000),
		Active			INT	NOT NULL,
		MarketDealerTableTxt	VARCHAR(100) NOT NULL, 
    [PAGCode] NVARCHAR(10) NULL, 
    [DealerName] NVARCHAR(150) NULL
);

