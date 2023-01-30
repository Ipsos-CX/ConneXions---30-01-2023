CREATE TABLE [SelectionOutput].[HotTopics] (
	[HotTopicID]			INT IDENTITY(1,1) NOT NULL, 
    [HotTopicCode]			VARCHAR(10)  NOT NULL,
    [HotTopicDescription]	VARCHAR(100) NOT NULL,
    [ThroughDate]			DATETIME2 NULL
);

