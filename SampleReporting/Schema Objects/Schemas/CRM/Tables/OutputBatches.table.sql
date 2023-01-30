CREATE TABLE [CRM].[OutputBatches]
(
	Batch	INT NOT NULL, 
	Row		INT NOT NULL,
	NSCRef	NVARCHAR(255),
	CaseID	INT NOT NULL,
	OutputFlag	VARCHAR(1),
	EventID BIGINT NOT NULL,
	OutputResponseStatusID  INT,
	LoadToConnexionsDate DATETIME NULL,
	Unsubscribe		BIT NULL,
	Bounceback		BIT NULL
	
)
