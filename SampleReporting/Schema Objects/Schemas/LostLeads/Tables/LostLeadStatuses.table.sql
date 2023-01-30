CREATE TABLE [LostLeads].[LostLeadStatuses]
(
	[LeadStatusID]			[int] IDENTITY(1,1) NOT NULL,
	[LeadStatus]			[varchar](50) NOT NULL,
	[LeadStatusCRMKeyValue]	[varchar](20) NOT NULL,
	[ContactedByGfKFlag]	CHAR(1) NOT NULL,
	[PassedToLLAFlag]		CHAR(1) NOT NULL,
	[Precedence]			[int] NOT NULL
) 
