CREATE TABLE [Audit].[GermanyRedFlagReportData]
(
	[AuditID]						INT NOT NULL,
	[AuditItemID]					INT NOT NULL,
	[Survey ID]						INT NULL,
	[Creationdate]					NVARCHAR(255) NULL,
	[Survey Type]					NVARCHAR(255) NULL,
	[Source of this Survey]			NVARCHAR(255) NULL,
	[Survey status]					NVARCHAR(255) NULL,
	[Record has/had red flag issue] NVARCHAR(255) NULL,
	[Alert Closed Within 72 Hours]	NVARCHAR(255) NULL,
	[Response Date]					NVARCHAR(255) NULL,
	[Case ID]						NVARCHAR(255) NULL,
	[Event ID]						NVARCHAR(255) NULL,
	[Brand]							NVARCHAR(255) NULL,
	[Dealer Party ID]				NVARCHAR(255) NULL
) ON [PRIMARY]