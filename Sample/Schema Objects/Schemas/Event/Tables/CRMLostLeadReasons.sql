CREATE TABLE [Event].[CRMLostLeadReasons]
(
	[CaseID]						INT NOT NULL,
	[EventID]						INT NOT NULL,
	[SV-CRM Lead Status]			NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 1]	NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 2]	NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 3]	NVARCHAR(255) NULL,
	[Notes]							NVARCHAR(MAX) NULL, 
    [RecontactDate]					DATETIME NULL
)
