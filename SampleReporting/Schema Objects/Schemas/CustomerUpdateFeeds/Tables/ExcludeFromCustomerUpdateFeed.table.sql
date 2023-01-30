CREATE TABLE [CustomerUpdateFeeds].[ExcludeFromCustomerUpdateFeed]
(
	[Brand]                              NVARCHAR(510)   NULL, -- BUG 15062
    [Market]                             VARCHAR(200)    NULL,
    [Questionnaire]                      VARCHAR(255)    NULL,
    [Exclude]							 BIT         NOT NULL 
)
