CREATE TABLE Event.CRMLostLeadCodeframes
(
	[Question]						NVARCHAR(255) NULL,
	[Code]							INT NULL,
	[MedalliaResponse]				NVARCHAR(255) NULL,
	[Response]						NVARCHAR(255) NULL,
	[PreviousQuestion]				NVARCHAR(255) NULL,
	[PreviousCode]					INT NULL,
	[SV-CRM Lead Status]			NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 1]	NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 2]	NVARCHAR(255) NULL,
	[SV-CRM Lead Status Reason 3]	NVARCHAR(255) NULL, 
    [Priority]						INT NULL
) ON [PRIMARY]