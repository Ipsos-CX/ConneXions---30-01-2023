CREATE TABLE [Event].[CRMLostLeadResponses]
(
	CaseID		INT NOT NULL,
	EventID		INT NOT NULL,
	Question	NVARCHAR(255) NULL,
	Code		INT NULL,
	Response	NVARCHAR(MAX) NULL
)
