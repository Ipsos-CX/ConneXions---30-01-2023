CREATE TABLE [Requirement].[QuestionnaireModelRequirements]
(
	RequirementIDMadeUpOf dbo.RequirementID NOT NULL, 
	RequirementIDPartOf dbo.RequirementID NOT NULL,
	PostalQuota INT NULL,
	EmailQuota INT NULL,
	PhoneQuota INT NULL,
	TotalQuota	INT NULL,
	TotalQuotaPercentage INT NULL,
	FromDate DATETIME2 NOT NULL,
	ThroughDate DATETIME2 NULL
)
